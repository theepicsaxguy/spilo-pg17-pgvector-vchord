#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Validating PostgreSQL extensions build..."

CONTAINER_NAME="test-spilo-extensions"
IMAGE_NAME="${1:-test-image}"

cleanup() {
    echo "🧹 Cleaning up test container..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "🚀 Starting PostgreSQL container: $IMAGE_NAME"
docker run -d --name "$CONTAINER_NAME" \
  -e POSTGRES_PASSWORD=testpass \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_USER=postgres \
  -e SPILO_CONFIGURATION='{"postgresql":{"parameters":{"shared_preload_libraries":"bg_mon,pg_stat_statements,pgextwlist,pg_auth_mon,set_user,pg_cron,vchord"}}}' \
  "$IMAGE_NAME"

echo "⏳ Waiting for PostgreSQL to be ready..."
attempt=1 max_attempts=30
until docker exec "$CONTAINER_NAME" pg_isready -U postgres >/dev/null 2>&1 \
      || [ $attempt -gt $max_attempts ]; do
    echo "  Attempt $attempt of $max_attempts..."
    attempt=$((attempt+1))
    sleep 2
done
if [ $attempt -gt $max_attempts ]; then
    echo "❌ PostgreSQL failed to start"; docker logs "$CONTAINER_NAME"; exit 1
fi
echo "✅ PostgreSQL is ready!"

echo "🔎 Verifying vchord is pre-loaded..."
attempt=1
until docker exec "$CONTAINER_NAME" psql -U postgres -XtAc "SHOW shared_preload_libraries" \
        | grep -qw vchord \
        || [ $attempt -gt 10 ]; do
    sleep 2; attempt=$((attempt+1))
done
if [ $attempt -gt 10 ]; then
    echo "❌ vchord not found in shared_preload_libraries"; exit 1
fi
echo "✅ vchord is pre-loaded"

echo "🧪 Testing pgvector extension..."
docker exec "$CONTAINER_NAME" psql -U postgres -d postgres -c \
  "CREATE EXTENSION IF NOT EXISTS vector;
   SELECT 'vector version: '||extversion FROM pg_extension WHERE extname='vector';"

echo "🧪 Testing vchord extension..."
docker exec "$CONTAINER_NAME" psql -U postgres -d postgres -c \
  "CREATE EXTENSION IF NOT EXISTS vchord;
   SELECT 'vchord version: '||extversion FROM pg_extension WHERE extname='vchord';"

echo "🧪 Testing basic vector operations..."
docker exec "$CONTAINER_NAME" psql -U postgres -d postgres -c "
  CREATE TABLE test_vectors (id serial, embedding vector(3));
  INSERT INTO test_vectors (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
  SELECT id, embedding, embedding <-> '[1,2,3]' AS distance
    FROM test_vectors ORDER BY distance;
  CREATE INDEX test_idx ON test_vectors USING vchord (embedding vector_l2_ops);
  SELECT 'Index created: '||indexname FROM pg_indexes WHERE tablename='test_vectors';
"

if docker exec "$CONTAINER_NAME" test -f /scripts/test-extensions.sql 2>/dev/null; then
    echo "🧪 Running comprehensive extension test..."
    docker exec "$CONTAINER_NAME" psql -U postgres -d postgres \
      -f /scripts/test-extensions.sql
else
    echo "⚠️  Comprehensive test script not found, running basic validation only"
fi

echo "📊 Extension summary:"
docker exec "$CONTAINER_NAME" psql -U postgres -d postgres -c "
  SELECT extname AS extension, extversion AS version, 'installed' AS status
  FROM pg_extension WHERE extname IN ('pgvector','vchord') ORDER BY extname;
"

echo "🎉 All validation tests passed!"

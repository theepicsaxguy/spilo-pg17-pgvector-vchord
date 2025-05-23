#!/bin/bash
set -e

echo "🔍 Validating PostgreSQL extensions build..."

# Container name for testing
CONTAINER_NAME="test-spilo-extensions"
IMAGE_NAME="${1:-test-image}"

# Cleanup function
cleanup() {
    echo "🧹 Cleaning up test container..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

echo "🚀 Starting PostgreSQL container: $IMAGE_NAME"
docker run --rm -d --name "$CONTAINER_NAME" \
    -e POSTGRES_PASSWORD=testpass \
    -e POSTGRES_DB=testdb \
    -e POSTGRES_USER=postgres \
    "$IMAGE_NAME"

echo "⏳ Waiting for PostgreSQL to be ready..."
timeout 60s bash -c "
    until docker exec $CONTAINER_NAME pg_isready -U postgres; do 
        echo '  ... still waiting'
        sleep 2
    done
"

echo "✅ PostgreSQL is ready!"

echo "🧪 Testing pgvector extension..."
docker exec "$CONTAINER_NAME" psql -U postgres -d testdb -c "
    CREATE EXTENSION IF NOT EXISTS pgvector;
    SELECT 'pgvector version: ' || extversion FROM pg_extension WHERE extname = 'pgvector';
"

echo "🧪 Testing vchord extension..."
docker exec "$CONTAINER_NAME" psql -U postgres -d testdb -c "
    CREATE EXTENSION IF NOT EXISTS vchord;
    SELECT 'vchord version: ' || extversion FROM pg_extension WHERE extname = 'vchord';
"

echo "🧪 Testing basic vector operations..."
docker exec "$CONTAINER_NAME" psql -U postgres -d testdb -c "
    -- Test vector creation and basic operations
    CREATE TABLE test_vectors (id serial, embedding vector(3));
    INSERT INTO test_vectors (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
    
    -- Test similarity search
    SELECT id, embedding, embedding <-> '[1,2,3]' as distance 
    FROM test_vectors 
    ORDER BY distance;
    
    -- Test vchord index creation
    CREATE INDEX test_idx ON test_vectors USING vchord (embedding vector_l2_ops);
    
    -- Verify index exists
    SELECT 'Index created: ' || indexname FROM pg_indexes WHERE tablename = 'test_vectors';
"

echo "🧪 Running comprehensive extension test..."
if [ -f "/scripts/test-extensions.sql" ]; then
    docker exec "$CONTAINER_NAME" psql -U postgres -d testdb -f /scripts/test-extensions.sql
else
    echo "⚠️  Comprehensive test script not found, running basic validation only"
fi

echo "📊 Extension summary:"
docker exec "$CONTAINER_NAME" psql -U postgres -d testdb -c "
    SELECT 
        extname as extension,
        extversion as version,
        'installed' as status
    FROM pg_extension 
    WHERE extname IN ('pgvector', 'vchord')
    ORDER BY extname;
"

echo "🎉 All validation tests passed!"
echo "✅ pgvector and vchord extensions are properly installed and functional"
#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="test-spilo-pg-extensions"
IMAGE_NAME="${1:-spilo-pg17-ext:test}"

dump_logs() {
    echo -e "\n🚨 Dumping container logs for debugging:"
    docker logs "$CONTAINER_NAME" || true
}

cleanup() {
    echo "🧹 Cleaning up..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

echo "🚀 Starting test container"
docker run -d --name "$CONTAINER_NAME" \
  -e POSTGRES_PASSWORD=testpass \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_USER=postgres \
  -e PGUSER=postgres \
  -e PGPASSWORD=testpass \
  -e SCOPE=ci \
  -e PGVERSION=17 \
  "$IMAGE_NAME"

# Wait for readiness WITHOUT ERR TRAP
ready=0
for i in {1..30}; do
    set +e
    output=$(docker exec "$CONTAINER_NAME" pg_isready -U postgres 2>&1)
    status=$?
    set -e
    echo "Attempt $i: $output (exit code $status)"
    if [[ "$output" == *"accepting connections"* ]] && [[ $status -eq 0 ]]; then
        echo "✅ PostgreSQL is ready"
        ready=1
        break
    fi
    sleep 1
done

if [[ "$ready" != "1" ]]; then
    echo "❌ PostgreSQL never became ready"
    dump_logs
    exit 1
fi

# From here, ERR trap is fine (fatal means logs are still available)
set -eE
trap 'dump_logs; exit 1' ERR

echo "📦 Verifying extension files"
docker exec "$CONTAINER_NAME" ls -l /usr/share/postgresql/17/extension/ | grep -E 'pgvector|vchord'

echo "🧪 Verifying extensions via SQL"
docker exec "$CONTAINER_NAME" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS pgvector;"
docker exec "$CONTAINER_NAME" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS vchord;"

docker exec "$CONTAINER_NAME" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "
    SELECT extname, extversion 
    FROM pg_extension 
    WHERE extname IN ('pgvector', 'vchord');
"

echo "✅ All extension checks passed"

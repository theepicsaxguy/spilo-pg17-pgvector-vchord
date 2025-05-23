#!/bin/bash
set -e

IMAGE_NAME="spilo-pg17-ext:test"
CONTAINER_NAME="test-spilo-debug"

# Clean up existing container
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Build the image if needed
docker inspect "$IMAGE_NAME" >/dev/null 2>&1 || docker build -t "$IMAGE_NAME" ..

echo "🚀 Starting container for debugging..."
docker run -d --name "$CONTAINER_NAME" \
    -e POSTGRES_PASSWORD=testpass \
    -e POSTGRES_DB=testdb \
    -e POSTGRES_USER=postgres \
    "$IMAGE_NAME"

echo "📋 Container logs (streaming for 30 seconds):"
docker logs -f "$CONTAINER_NAME" &
log_pid=$!

# Wait for 30 seconds then kill the logs process
sleep 30
kill $log_pid 2>/dev/null || true

# Check container status
echo "📊 Container status:"
docker ps -a -f name="$CONTAINER_NAME" --format "{{.Status}}"

# Check if PostgreSQL is ready
echo "⚠️  Testing PostgreSQL readiness:"
docker exec "$CONTAINER_NAME" pg_isready -U postgres || echo "PostgreSQL not ready"

echo "🔍 Container inspection:"
docker inspect "$CONTAINER_NAME" --format="ExitCode: {{.State.ExitCode}}, Status: {{.State.Status}}, Error: {{.State.Error}}"

# Keep container running for manual inspection
echo "✅ Test complete. Container '$CONTAINER_NAME' is still running for manual inspection."
echo "Run 'docker exec -it $CONTAINER_NAME bash' to connect to the container."
echo "Run 'docker rm -f $CONTAINER_NAME' to remove the container when finished."

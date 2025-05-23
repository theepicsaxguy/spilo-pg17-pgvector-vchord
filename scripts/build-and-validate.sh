#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Default image name and tag
IMAGE_NAME="spilo-pg17-ext:test"

# Build the image
echo "🏗️ Building Docker image..."
docker build -t "$IMAGE_NAME" "$PROJECT_ROOT"

# Run validation
echo "🔍 Running validation..."
"$SCRIPT_DIR/validate-build.sh" "$IMAGE_NAME"

echo "✨ Build and validation complete!"

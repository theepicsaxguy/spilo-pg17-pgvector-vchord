#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

SPILO_SUBMODULE_PATH="${PROJECT_ROOT}/spilo-upstream/postgres-appliance"

REGISTRY="ghcr.io"
OWNER="theepicsaxguy"
SPILO_IMAGE_REPO_NAME="spilo-pg17-pgvector-vchord"
SPILO_IMAGE_TAG="base"  # Changed to match your original script

FULL_SPILO_IMAGE_NAME="${REGISTRY}/${OWNER}/${SPILO_IMAGE_REPO_NAME}:${SPILO_IMAGE_TAG}"

echo "--- Building Spilo base image from submodule (${SPILO_SUBMODULE_PATH}) ---"
echo "--- Target image: ${FULL_SPILO_IMAGE_NAME} ---"

# Ensure submodule is updated
git -C "${PROJECT_ROOT}" submodule update --init --recursive --remote

# Verify buildx is available
docker buildx version >/dev/null 2>&1 || {
    echo "Error: Docker Buildx not available. Please install or enable."
    exit 1
}

# Create a builder instance if not exists
docker buildx inspect multiarch-builder >/dev/null 2>&1 || {
    docker buildx create --name multiarch-builder
}

# Switch to the multiarch builder
docker buildx use multiarch-builder

# Bootstrap the builder
docker buildx inspect --bootstrap

# Build and push with detailed progress
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg PGVERSION=17 \
    --build-arg DEB_PG_SUPPORTED_VERSIONS="17" \
    -t "${FULL_SPILO_IMAGE_NAME}" \
    --push \
    --progress=plain \
    "${SPILO_SUBMODULE_PATH}"

echo "--- Spilo base image build and push complete! ---"
echo "Pushed: ${FULL_SPILO_IMAGE_NAME}"
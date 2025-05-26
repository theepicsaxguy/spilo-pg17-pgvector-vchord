#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

SPILO_SUBMODULE_PATH="${PROJECT_ROOT}/spilo-upstream/postgres-appliance"

# Define the image name and tag for the Spilo base image in GHCR
# Example: ghcr.io/theepicsaxguy/spilo-base-pg17:latest
# Or use a specific version/date tag if you prefer, e.g., :20250527
REGISTRY="ghcr.io"
OWNER="theepicsaxguy" # Or your GitHub username/org
SPILO_BASE_IMAGE_REPO_NAME="spilo-pg17-pgvector-vchord"
SPILO_BASE_IMAGE_TAG="base"

FULL_SPILO_BASE_IMAGE_NAME="${REGISTRY}/${OWNER}/${SPILO_BASE_IMAGE_REPO_NAME}:${SPILO_BASE_IMAGE_TAG}"

echo "--- Building Spilo base image from submodule (${SPILO_SUBMODULE_PATH}) ---"
echo "--- Target image: ${FULL_SPILO_BASE_IMAGE_NAME} ---"

# Ensure submodule is updated locally before building
git -C "${PROJECT_ROOT}" submodule update --init --recursive --remote

# Build for multiple platforms if your local Docker setup supports it (e.g., Docker Desktop with buildx)
# Otherwise, build for your current architecture.
# For multi-arch, you might need to set up a buildx builder.
# docker buildx create --use --name mybuilder (if not already done)
# docker buildx build --builder mybuilder ...

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg PGVERSION=17 \
  --build-arg DEB_PG_SUPPORTED_VERSIONS="17" \
  -t "${FULL_SPILO_BASE_IMAGE_NAME}" \
  --push \
  "${SPILO_SUBMODULE_PATH}"

echo "--- Spilo base image build and push complete! ---"
echo "Pushed: ${FULL_SPILO_BASE_IMAGE_NAME}"
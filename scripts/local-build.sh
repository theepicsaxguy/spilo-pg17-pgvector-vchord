#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

SPILO_SUBMODULE_PATH="${PROJECT_ROOT}/spilo-upstream/postgres-appliance"
TEMP_BASE_TAG="spilo-base-temp:latest" # Must match your Dockerfile

FINAL_IMAGE_TAG="ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:local-dev" # Or any local tag you prefer

echo "--- Step 1: Building Spilo base image from submodule (${SPILO_SUBMODULE_PATH}) ---"
# Ensure submodule is updated locally before building
git -C "${PROJECT_ROOT}" submodule update --init --recursive --remote
docker build -t "${TEMP_BASE_TAG}" "${SPILO_SUBMODULE_PATH}"

echo "--- Step 2: Building final image (${FINAL_IMAGE_TAG}) using local base ---"
docker build -t "${FINAL_IMAGE_TAG}" "${PROJECT_ROOT}"

echo "--- Local build complete! ---"
echo "You can now run your image:"
echo "docker run -d --name my-test-db -p 5432:5432 -e POSTGRES_PASSWORD=test ${FINAL_IMAGE_TAG}"
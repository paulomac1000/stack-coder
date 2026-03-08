#!/bin/bash
# scripts/run_tests.sh
# Runs tests inside Docker containers.
# Usage: ./scripts/run_tests.sh [unit|integration|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_IMAGE="coder-unit-tests"
MODE="${1:-all}"

# Function for unit tests (fast Alpine container)
run_unit_tests() {
    echo ">>> [UNIT] Building test image..."
    docker build -f "$PROJECT_DIR/Dockerfile.test" -t "$TEST_IMAGE" "$PROJECT_DIR" --quiet

    echo ">>> [UNIT] Running tests in container..."
    # Mount the code as read-only to prevent tests from modifying the source code
    docker run --rm \
        -v "$PROJECT_DIR:/var/apps/coder:ro" \
        -w /var/apps/coder \
        "$TEST_IMAGE" \
        bash scripts/unit_tests.sh
}

# Function for integration tests (full Docker Compose stack)
run_integration_tests() {
    echo ">>> [INTEGRATION] Starting environment (Docker Compose)..."
    
    # Make sure the containers are fresh
    docker compose -f "$PROJECT_DIR/docker-compose.yml" \
        --project-directory "$PROJECT_DIR" \
        down --remove-orphans

    docker compose -f "$PROJECT_DIR/docker-compose.yml" \
        --project-directory "$PROJECT_DIR" \
        up -d --wait

    echo ">>> [INTEGRATION] Executing tests inside the code-server container..."
    # We call the integration script inside the running container
    if docker exec code-server bash /var/apps/coder/scripts/integration_tests.sh; then
        echo ">>> [INTEGRATION] Tests finished successfully."
        EXIT_CODE=0
    else
        echo ">>> [INTEGRATION] Tests failed."
        EXIT_CODE=1
    fi

    echo ">>> [INTEGRATION] Cleaning up environment..."
    docker compose -f "$PROJECT_DIR/docker-compose.yml" \
        --project-directory "$PROJECT_DIR" \
        down

    return $EXIT_CODE
}

# Main mode selection logic
case "$MODE" in
    unit)
        run_unit_tests
        ;;
    integration)
        run_integration_tests
        ;;
    all)
        run_unit_tests
        run_integration_tests
        ;;
    *)
        echo "Usage: $0 [unit|integration|all]"
        exit 1
        ;;
esac

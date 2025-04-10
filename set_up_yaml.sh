#!/bin/bash
set -euxo pipefail

# Parameter validation
if [ $# -ne 3 ]; then
    echo "Usage: $0 TASK_ID REPO COMMIT"
    exit 1
fi

TASK_ID="$1"
REPO="$2"
COMMIT="$3"

# Path setup
EXPR_PATH=/opt/tiger/expr
ENV_PATH="${EXPR_PATH}/conda_env/${TASK_ID}"
TEST_BED_PATH="${EXPR_PATH}/testbed/${TASK_ID}"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")  
CONDA_YAML_PATH="${SCRIPT_DIR}/conda_yaml/${TASK_ID}.yml"
TEST_PATCH_PATH="${SCRIPT_DIR}/swe-bench-extra/${TASK_ID}/test_patch.diff"


echo "Setting up test environment for task ID: $TASK_ID"
echo "Repository: $REPO"
echo "Commit: $COMMIT"
echo "Conda environment path: $ENV_PATH"
echo "Test bed path: $TEST_BED_PATH"
# # Create necessary directories
# mkdir -p $(dirname $ENV_PATH)
# mkdir -p $(dirname $TEST_BED_PATH)

# Check Miniconda
if [ ! -f /opt/miniconda3/bin/activate ]; then
    echo "Error: Miniconda3 not installed"
    exit 1
fi

# Trap to clean up on failure
cleanup() {
    EXIT_CODE=$?  # 捕获原始退出码
    echo "Set up failed. Cleaning up..."
    rm -rf "$ENV_PATH" "$TEST_BED_PATH"
    echo "Cleanup completed."
    exit $EXIT_CODE  # 使用原始退出码退出
}
trap cleanup ERR

# Create and activate environment
# 初始化 conda
eval "$(/opt/miniconda3/bin/conda shell.bash hook)"
echo "Activating Miniconda3..."

if [ -d "$ENV_PATH" ]; then
    # echo "Warning: Environment already exists at $ENV_PATH, skip it"
    # exit 0
    echo "Error: Environment already exists at $ENV_PATH, rebuild it"
    sudo rm -rf "$ENV_PATH"
    sudo rm -rf "$TEST_BED_PATH"
fi

# Create new environment
conda env create -f "$CONDA_YAML_PATH" --prefix $ENV_PATH

echo "Environment created at $ENV_PATH"
# Activate environment
conda activate $ENV_PATH
# Display current environment
echo "Current environment: $CONDA_DEFAULT_ENV"

# Display final environment
conda list

echo "Start preparing Testbed....."

# Setup test environment
if [ -d "$TEST_BED_PATH" ]; then
    echo "Warning: Test directory exists, removing..."
    rm -rf "$TEST_BED_PATH"
fi

# Clone repository with retry logic
RETRY_COUNT=0
MAX_RETRIES=5
DELAY=30

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if git clone -o origin "https://github.com/$REPO" "$TEST_BED_PATH"; then
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo "Error: Failed to clone repository after $MAX_RETRIES attempts"
            exit 1
        fi
        echo "Clone failed. Retrying in $DELAY seconds... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep $DELAY
        DELAY=$((DELAY + 10))
    fi
done

chmod -R 777 "$TEST_BED_PATH"
cd "$TEST_BED_PATH"
git reset --hard "$COMMIT"
git clean -fd
git remote remove origin
git config --global --add safe.directory "$TEST_BED_PATH"
git status
git show

echo "Environment set up"

: ">>>>> Start Applying Test Patch"
git apply --verbose "$TEST_PATCH_PATH"
if [ $? -ne 0 ]; then
    # 如果失败，尝试强制应用
    echo "Warning: Normal apply failed, trying force apply..."
    git apply --reject --verbose $TEST_PATCH_PATH
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to apply patch even with force: $TEST_PATCH_PATH"
        exit 1
    fi
fi
: ">>>>> End Applying Test Patch"

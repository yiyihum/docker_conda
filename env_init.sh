#!/bin/bash
set -xuo pipefail

# 帮助函数
show_usage() {
    echo "用法: $0 TASK_ID COMMIT TEST_COMMAND"
    echo "示例: $0 task123 abc123 'pytest test_file.py'"
    echo ""
    echo "参数说明:"
    echo "  TASK_ID      - 任务ID"
    echo "  COMMIT       - Git commit hash"
    exit 1
}

# 参数检查
if [ $# -lt 2 ]; then
    show_usage
fi

# 参数设置
TASK_ID="$1"
COMMIT="$2"

# 路径设置
EXPR_PATH="/opt/tiger/expr"
TEST_BED_PATH="${EXPR_PATH}/testbed/${TASK_ID}"
TEST_PATCH_PATH="./swe-bench-extra/${TASK_ID}/test_patch.diff"

# 测试目录必须存在
if [ ! -d "$TEST_BED_PATH" ]; then
    echo "ERROR: $TEST_BED_PATH not found"
    exit 1
fi
# 进入测试目录
cd "$TEST_BED_PATH"

# Git配置和操作
# git config --global --add safe.directory "$TEST_BED_PATH"
git reset --hard "$COMMIT"
git clean -fd  
git status
git show
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
# # 执行测试
# : ">>>>> Start Test Output"
# $TEST_COMMAND
# : '>>>>> End Test Output'

# git reset --hard "$COMMIT"

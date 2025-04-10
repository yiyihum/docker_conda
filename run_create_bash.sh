#!/bin/bash  
set -x
mkdir /tmp/setup_log
SCRIPTS_DIR="/docker_conda/create_bash"  

# 对目录中所有.sh文件运行  
for script in "$SCRIPTS_DIR"/*.sh; do  
    if [ -f "$script" ] && [ -x "$script" ]; then  
        echo "启动: $script"  
        bash "$script" &   # & 让脚本在后台运行  
    fi  
done  

# 等待所有后台进程完成  
wait  
echo "所有脚本执行完毕"  
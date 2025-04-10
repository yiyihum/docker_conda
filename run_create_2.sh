#!/bin/bash  

# 配置参数  
INPUT_FILE="/docker_conda/test.sh"  
MAX_PARALLEL=64 
LOG_DIR="/tmp/parallel_execution_logs"  

# 创建日志目录  
mkdir -p "$LOG_DIR"  
echo "开始执行时间: $(date)" > "$LOG_DIR/master.log"  

# 检查输入文件是否存在  
if [ ! -f "$INPUT_FILE" ]; then  
    echo "错误: 输入文件 $INPUT_FILE 不存在!" | tee -a "$LOG_DIR/master.log"  
    exit 1  
fi  

# 初始化计数器和PID数组  
running_count=0  
pids=()  

# 函数: 等待任意一个任务完成并更新计数器  
wait_for_any_job() {  
    local new_pids=()  
    for pid in "${pids[@]}"; do  
        if kill -0 $pid 2>/dev/null; then  
            new_pids+=($pid)  
        fi  
    done  
    
    # 更新正在运行的进程列表和计数  
    pids=("${new_pids[@]}")  
    running_count=${#pids[@]}  
}  

# 读取每一行并执行  
line_num=0  
while IFS= read -r cmd || [ -n "$cmd" ]; do  
    # 跳过空行和注释行  
    if [[ -z "$cmd" || "$cmd" =~ ^[[:space:]]*# ]]; then  
        continue  
    fi  
    
    line_num=$((line_num + 1))  
    
    # 等待有可用槽位  
    while [ $running_count -ge $MAX_PARALLEL ]; do  
        sleep 1  
        wait_for_any_job  
    done  
    
    # 执行命令  
    echo "启动任务 $line_num: $cmd" | tee -a "$LOG_DIR/master.log"  
    
    # 将命令输出重定向到对应的日志文件，并在后台执行  
    (  
        echo "开始执行时间: $(date)" > "$LOG_DIR/task_${line_num}.log"  
        echo "执行命令: $cmd" >> "$LOG_DIR/task_${line_num}.log"  
        echo "-----------------" >> "$LOG_DIR/task_${line_num}.log"  
        
        # 执行命令，捕获退出状态  
        eval "$cmd" >> "$LOG_DIR/task_${line_num}.log" 2>&1  
        exit_status=$?  
        
        echo "-----------------" >> "$LOG_DIR/task_${line_num}.log"  
        echo "结束时间: $(date)" >> "$LOG_DIR/task_${line_num}.log"  
        echo "退出状态: $exit_status" >> "$LOG_DIR/task_${line_num}.log"  
        
        if [ $exit_status -eq 0 ]; then  
            echo "任务 $line_num 成功完成" >> "$LOG_DIR/master.log"  
        else  
            echo "任务 $line_num 失败，退出码: $exit_status" >> "$LOG_DIR/master.log"  
        fi  
    ) &  
    
    # 记录PID并更新计数  
    pids+=($!)  
    running_count=${#pids[@]}  
    
    echo "当前运行任务数: $running_count/$MAX_PARALLEL" | tee -a "$LOG_DIR/master.log"  
    
    # 稍微延迟，避免同时启动过多进程  
    sleep 0.1  
    
done < "$INPUT_FILE"  

# 等待所有剩余任务完成  
echo "所有任务已启动，等待剩余 $running_count 个任务完成..." | tee -a "$LOG_DIR/master.log"  
wait  

echo "完成所有执行，总共执行了 $line_num 个任务" | tee -a "$LOG_DIR/master.log"  
echo "结束时间: $(date)" | tee -a "$LOG_DIR/master.log"  
echo "日志文件保存在: $LOG_DIR"  

#!/bin/bash  

# 源目录和目标目录  
SOURCE_DIR="/opt/tiger/expr/conda_env"  
TARGET_DIR="/mnt/bn/tiktok-mm-5/aiic/users/yiming/docker_conda/conda_yaml"  

# 确保目标目录存在  
mkdir -p "$TARGET_DIR"  

# 查找源目录下的所有子目录（每个子目录代表一个conda环境）  
echo "开始导出Conda环境配置..."  
echo "源目录: $SOURCE_DIR"  
echo "目标目录: $TARGET_DIR"  

# 计数器  
count=0  

# 遍历所有环境目录  
for env_path in "$SOURCE_DIR"/*; do  
    # 确保是目录  
    if [ -d "$env_path" ]; then  
        # 获取环境名（目录名）  
        env_name=$(basename "$env_path")  
        
        # 输出文件路径  
        output_file="$TARGET_DIR/${env_name}.yml"  
        
        echo "正在导出: $env_name"  
        
        # 导出环境配置（不包含构建信息）  
        conda env export --no-builds -p "$env_path" > "$output_file"  
        
        # 检查是否成功  
        if [ $? -eq 0 ]; then  
            echo "✓ 成功导出: $output_file"  
            count=$((count+1))  
        else  
            echo "✗ 导出失败: $env_name"  
        fi  
    fi  
done  

echo "导出完成! 共导出 $count 个环境配置" 
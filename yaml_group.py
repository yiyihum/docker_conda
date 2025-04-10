#!/usr/bin/env python3  
import os  
from collections import defaultdict  

# 设置目录路径  
yaml_dir = "/mnt/bn/tiktok-mm-5/aiic/users/yiming/docker_conda/conda_yaml"  

# 存储分组结果的字典  
dependency_groups = defaultdict(list)  

# 遍历目录中的所有文件  
for filename in os.listdir(yaml_dir):  
    if filename.endswith(".yml") or filename.endswith(".yaml"):  
        file_path = os.path.join(yaml_dir, filename)  
        end_pos = -1
        start_pos = -1
        try:  
            # 读取文件内容  
            with open(file_path, 'r') as file:  
                content = file.read()  
                
                # 寻找依赖部分  
                try:  
                    # 找到dependencies:和prefix:之间的内容  
                    start_marker = "dependencies:"  
                    end_marker = "prefix:"  
                    
                    start_pos = content.find(start_marker)  
                    if start_pos == -1:  
                        print(f"警告：{filename} 中未找到dependencies部分")  
                        continue  
                        
                    # 跳过dependencies:行本身  
                    start_pos = content.find("\n", start_pos) + 1  
                    
                    # 找到prefix:行或文件结尾  
                    end_pos = content.find(end_marker, start_pos)  
                    if end_pos == -1:  
                        # 如果没有prefix行，使用文件结尾  
                        dependencies_content = content[start_pos:].strip()  
                    else:  
                        dependencies_content = content[start_pos:end_pos].strip()  
                    
                    # 将文件添加到相应的依赖组  
                    dependency_groups[dependencies_content].append(filename.split(".yml")[0])

                    # 检查dependencies_content里面有没有本地目录
                    if "-e " in dependencies_content:
                        print(file_path)

                    
                except Exception as e:  
                    print(f"处理 {filename} 时出错: {e}")  
                    
        except Exception as e:  
            print(f"无法读取 {filename}: {e}")  

# 输出分组结果  
print(f"一共有 {len(os.listdir(yaml_dir))} 个文件") 
print(f"找到 {len(dependency_groups)} 个不同的依赖组")  
print("=" * 50)  

import json
# 保存分组结果到文件
dependency_groups_json ={}
for deps, files in dependency_groups.items():
    # 只保留文件名，不保留路径
    dependency_groups_json[files[0]] = files
with open("dependency_groups.json", "w") as f:
    json.dump(dependency_groups_json, f, indent=4)


# for i, (deps, files) in enumerate(dependency_groups.items(), 1):  
#     print(f"\n组 {i} (包含 {len(files)} 个文件):")  
#     print("-" * 50)  
    
#     # 打印组中的文件名  
#     print("文件:")  
#     for file in sorted(files):  
#         print(f"  - {file}")  
    
#     # 打印依赖项  
#     print("\n依赖列表:")  
#     if deps:  
#         print(deps)  
#     else:  
#         print("  (空依赖列表)")  
    
#     print("=" * 50)  
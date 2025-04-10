import os
from datasets import load_dataset
import json

data_path = "/mnt/bn/tiktok-mm-5/aiic/users/yiming/data/swe-bench-extra-message-good-20s-8k-wo-noisefile.jsonl"
tasks = load_dataset("json", data_files=data_path, split="train")
dependency_groups = "/mnt/bn/tiktok-mm-5/aiic/users/yiming/docker_conda/dependency_groups.json"
dependency_groups = json.load(open(dependency_groups, "r"))

# bash set_up_yaml.sh jtauber__termdoc-23 "jtauber/termdoc" 5de2d3d8ee9965da1a05a9b069683a7e1073f005 >/tmp/setup_log/jtauber__termdoc-23.log 2>&1

split=32
bash_paths = [f"/mnt/bn/tiktok-mm-5/aiic/users/yiming/docker_conda/create_bash/set_up_{i}.sh" for i in range(split)]
batch_size = len(tasks) // split

for i in range(split):
    bash_path = bash_paths[i]
    with open(bash_path, "w") as f:
        f.write("#!/bin/bash \nset -x\n")
        for task in tasks.shard(num_shards=split, index=i):
            instance_id = task["instance_id"]
            if instance_id in dependency_groups:
                repo = task["repo"]
                base_commit = task["base_commit"]
                cmd = f"bash set_up_yaml.sh {instance_id} \"{repo}\" {base_commit} >/tmp/setup_log/{instance_id}.log 2>&1\n"
                f.write(cmd)
# with open(bash_path, "w") as f:
#     f.write("#!/bin/bash \nset -x\nmkdir /tmp/setup_log\n")
#     for task in tasks:
#         instance_id = task["instance_id"]
#         if instance_id in dependency_groups:
#             repo = task["repo"]
#             base_commit = task["base_commit"]
#             cmd = f"bash set_up_yaml.sh {instance_id} \"{repo}\" {base_commit} >/tmp/setup_log/{instance_id}.log 2>&1\n"
#             f.write(cmd)

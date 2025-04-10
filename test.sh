#!/bin/bash 
set -x

mkdir /tmp/setup_log

# bash set_up_task.sh jtauber__termdoc-23 "jtauber/termdoc" 5de2d3d8ee9965da1a05a9b069683a7e1073f005 >/tmp/setup_log/jtauber__termdoc-23.log 2>&1
bash set_up_yaml.sh jtauber__termdoc-23 "jtauber/termdoc" 5de2d3d8ee9965da1a05a9b069683a7e1073f005 >/tmp/setup_log/jtauber__termdoc-23.log 2>&1
bash set_up_yaml.sh 0b01001001__spectree-64 "0b01001001/spectree" a091fab020ac26548250c907bae0855273a98778 >/tmp/setup_log/0b01001001__spectree-64.log 2>&1


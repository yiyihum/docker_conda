#!/bin/bash 
set -x
mkdir /tmp/init_log
mkdir /tmp/setup_log

bash set_up_task.sh jtauber__termdoc-23 "jtauber/termdoc" 5de2d3d8ee9965da1a05a9b069683a7e1073f005 
bash env_init.sh jtauber__termdoc-23 5de2d3d8ee9965da1a05a9b069683a7e1073f005

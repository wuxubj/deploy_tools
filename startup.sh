#!/bin/bash
date
cd
yum -y install vim git lrzsz net-tools
git clone https://github.com/wuxubj/deploy_tools.git
cd deploy_tools
mkdir log
sh tools/shadowsocks.sh deploy ss-server >> log/deploy.log 2>&1
date
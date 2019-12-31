#!/bin/bash
date
cd

#add id_rsa.pub
ssh_ras_pub="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzsQdqh2D2RGDrXAO/thitVtVi/tC0oTQj8l6uZ6+853wL8DaWuYxNVJa9gRt2ztOBpmwJvO0ocC/L9sbI79I+uhNBSg0xNequXOZ5sjBTEA03XSGf9oa68p67ue8mpdN8UJDNE/w6Zlp912bL50c7tRjwiZaD31/i7afUPZDZar3qfQbc8sFfsiRLy1VkpsnmB09TegyDuZfHTJlNieaDytjRmgCikoQkmhnmk/o3bv5+vw7yIMpkn09D8H6WyjgGaHjhmTOCy7ubL4OsSng8PLemqnptNCwQlw2KBzgLju7y849r+SDMr/tSuwrmDClAyZdnW4xYNH6zqGCTOlqT microway@macdeMBP.lan"
mkdir -p /root/.ssh
chmod 600 /root/.ssh
echo $ssh_ras_pub > /root/.ssh/authorized_keys
chmod 700 /root/.ssh/authorized_keys

#deploy shadowsocks
yum -y install vim git lrzsz net-tools
git clone https://github.com/wuxubj/deploy_tools.git
cd deploy_tools
mkdir log
sh tools/shadowsocks.sh deploy ss-server >> log/deploy.log 2>&1
date
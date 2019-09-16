#!/bin/bash

function usage()
{
    echo "usage: sh init_env.sh work/nginx/ss/python3"
    exit 0
}

function init_work()
{
    cd
    passwd
    groupadd work
    useradd -g work work
    passwd work
    chmod a+w /etc/sudoers
    echo "work    ALL=(ALL)       ALL" >> /etc/sudoers
    chmod a-w /etc/sudoers

    echo "start to "
    sleep 3
    #ssh-keygen  See https://www.liaohuqiu.net/cn/posts/ssh-keygen-abc/
    ssh-keygen
    #install netstat cmd
    yum install net-tools
    #install git  See https://www.jianshu.com/p/e6ecd86397fb
    yum install git
    git --version
    git config --global user.name "wuxubj"
    git config --global user.email "742745426@qq.com"
    git config --list
}
#install nginx
function deploy_nginx()
{
    cd
    #check existance of nginx
    check_str=$(whereis nginx | awk -F ': ' '{print $2}')
    echo "check_str:$check_str"
    if [ "$check_str" != "" ];then
        echo "nginx exist."
        whereis nginx
        nginx -V
        return
    fi
    #close firewall
    firewall-cmd --state
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    firewall-cmd --state
    #start install nginx
    yum install gcc-c++
    yum install -y pcre pcre-devel
    yum install -y zlib zlib-devel
    wget -c https://nginx.org/download/nginx-1.10.1.tar.gz
    tar -zxvf nginx-1.10.1.tar.gz
    cd nginx-1.10.1
    ./configure
    make
    make install
    #create soft link
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
    ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
    whereis nginx
    nginx
    ps aux | grep nginx
}

#shadowsocks
function deploy_shadowsocks()
{
    cd
    #install shadowsocks
    wget --no-check-certificate -O shadowsocksR.sh https://git.io/vHRHi
    chmod +x shadowsocksR.sh
    ./shadowsocksR.sh 2>&1 | tee shadowsocksR.log
    python /usr/local/shadowsocks/server.py -c /etc/shadowsocks.json -d start
    #install bbr
    wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
    chmod +x bbr.sh
    ./bbr.sh
    lsmod | grep bbr
}

function deploy_python3()
{
    cd
    #check existance of python3
    check_str=$(whereis python3 | awk -F ': ' '{print $2}')
    if [ "$check_str" != "" ];then
        echo "python3 exist."
        whereis python3
        whereis pip3
        python3 -V
        return
    fi
    #start install python3
    yum install make gcc gcc-c++ 
    python --version
    wget -c https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz
    tar -zxvf Python-3.6.4.tgz
    cd Python-3.6.4
    ./configure --prefix=/usr/local/python3 --enable-optimizations
    make
    make install
    #create soft link
    ln -s /usr/local/python3/bin/python3 /usr/bin/python3
    ln -s /usr/local/python3/bin/python3 /usr/local/bin/python3
    ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
    ln -s /usr/local/python3/bin/pip3 /usr/local/bin/pip3
    #show info
    whereis python3
    whereis pip3
    python3 -V
}

if [ $# -ne 1 ];then
    usage
fi
env="$1"
if [ "$env" == "work" ];then
    init_work
elif [ "$env" == "nginx" ];then
    deploy_nginx
elif [ "$env" == "ss" ];then
    deploy_shadowsocks
elif [ "$env" == "python3" ];then
    deploy_python3
else
    usage
fi
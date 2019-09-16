#!/bin/bash

if [ $# -ne 1 ];then
    echo "usage: sh init_env.sh work/nginx/ss"
    exit 0
fi

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
}
#install nginx
function deploy_nginx()
{
    cd
    firewall-cmd --state
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    firewall-cmd --state

    yum install gcc-c++
    yum install -y pcre pcre-devel
    yum install -y zlib zlib-devel
    wget -c https://nginx.org/download/nginx-1.10.1.tar.gz
    tar -zxvf nginx-1.10.1.tar.gz
    cd nginx-1.10.1
    ./configure
    make
    make install
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
    wget --no-check-certificate -O shadowsocksR.sh https://git.io/vHRHi
    chmod +x shadowsocksR.sh
    ./shadowsocksR.sh 2>&1 | tee shadowsocksR.log
    python /usr/local/shadowsocks/server.py -c /etc/shadowsocks.json -d start
    wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
    chmod +x bbr.sh
    ./bbr.sh
    lsmod | grep bbr
}

function deploy_python3()
{
    yum install make gcc gcc-c++ 
    python --version
    wget -c https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz
    tar -zxvf Python-3.6.4.tgz
    cd Python-3.6.4
    ./configure --prefix=/usr/local/python3 --enable-optimizations
    make
    make install
    python -V
    python3 -V

}
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
    echo "usage: sh init_env.sh work/nginx/ss"
    exit 0
fi
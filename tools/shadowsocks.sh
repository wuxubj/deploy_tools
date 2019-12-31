#!/bin/bash
#centos 7_x64

CUR_DIR=$(dirname $(readlink -f "$0"))
WORKSPACE=$CUR_DIR/..

function usage()
{
    commd=$1
    if [ "$commd" == "deploy" ];then
        echo "usage: sh shadowsocks.sh deploy ss/ss_server"
    elif [ "$commd" == "start" ];then
        echo "usage: sh shadowsocks.sh start ss/ss_server"
    elif [ "$commd" == "stop" ];then
        echo "usage: sh shadowsocks.sh stop ss/ss_server"
    elif [ "$commd" == "status" ];then
        echo "usage: sh shadowsocks.sh status ss/ss_server"
    else
        echo "usage: sh shadowsocks.sh deploy/start/stop/help"
    fi
    exit 0
}

#关闭防火墙
function stop_firewall()
{
    firewall-cmd --state
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    firewall-cmd --state
}

#install shadowsocks. See https://zoomyale.com/2016/vultr_and_ss/
function deploy_shadowsocks()
{
    cd $WORKSPACE
    #install shadowsocks
    wget --no-check-certificate -O shadowsocksR.sh https://git.io/vHRHi
    chmod +x shadowsocksR.sh
    ./shadowsocksR.sh 2>&1 | tee shadowsocksR.log
    python /usr/local/shadowsocks/server.py -c /etc/shadowsocks.json -d start
    ps aux | grep "shadowsocks.json" | grep -v "grep"
}

#install ss-server
function deploy_shadowsocks_libev()
{
    #安装
    cd $WORKSPACE
    yum install epel-release -y
    yum install gcc gettext autoconf libtool automake make pcre-devel asciidoc xmlto c-ares-devel libev-devel libsodium-devel mbedtls-devel -y
    cd /etc/yum.repos.d/
    curl -O https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo
    yum install -y shadowsocks-libev

    #修改配置文件
    cd $WORKSPACE
    config_file="config.json"
    echo "{" > $config_file
    echo "  \"server\":\"0.0.0.0\"," >> $config_file
    echo "  \"server_port\":13145," >> $config_file
    echo "  \"local_port\":1080," >> $config_file
    echo "  \"password\":\"fuckyou3times\"," >> $config_file
    echo "  \"timeout\":1000," >> $config_file
    echo "  \"method\":\"aes-256-cfb\"," >> $config_file
    echo "  \"mode\":\"tcp_and_udp\"" >> $config_file
    echo "}" >> $config_file
    mv /etc/shadowsocks-libev/config.json /etc/shadowsocks-libev/config.json.base
    cp $config_file /etc/shadowsocks-libev/config.json

    #重启
    cd $WORKSPACE
    systemctl restart shadowsocks-libev
    systemctl status shadowsocks-libev
    
}

function deploy_bbr()
{
    #install bbr
    cd $WORKSPACE
    #wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
    #chmod +x bbr.sh
    sh tools/bbr.sh
    lsmod | grep bbr
}

function stop_ss()
{
    cd $WORKSPACE
    pid=$(ps aux | grep "shadowsocks.json" | grep -v "grep" | awk '{print $2}')
    if [ ! -z "$pid" ];then
        echo "kill pid: $pid..."
        kill -9 $pid
    else
        echo "no running process."
    fi
}
function start_ss()
{
    cd $WORKSPACE
    python /usr/local/shadowsocks/server.py -c /etc/shadowsocks.json -d start
    ps aux | grep "shadowsocks.json" | grep -v "grep"
}

function stop_ss_server()
{
    cd $WORKSPACE
    app="$1"
    echo "stop ss-server $app..."
    if [ -z $app ];then
        systemctl stop shadowsocks-libev
    elif [ "$app" == "all" ];then
        pid=$(ps aux | grep "shadowsocks-libev" | grep "config" | grep -v "grep" | awk '{print $2}')
        if [ ! -z "$pid" ];then
            echo "kill pid: $pid..."
            kill -9 $pid
        fi
    else
        pid=$(ps aux | grep "shadowsocks-libev" | grep "config" | grep -v "grep" | grep "$app" | awk '{print $2}')
        if [ ! -z "$pid" ];then
            echo "kill pid: $pid..."
            kill -9 $pid
        fi
    fi

}

function start_ss_server()
{
    cd $WORKSPACE
    app="$1"
    echo "start ss-server $app..."
    if [ -z $app ];then
        systemctl restart shadowsocks-libev
    elif [ "$app" == "random" ];then
        cd /etc/shadowsocks-libev
        app=$(shuf -i 5000-65000 -n 1)
        if [ ! -f config_$app.json ];then
            cp config.json config_$app.json
            passwd=$(head -c 100 /dev/urandom | tr -dc a-z0-9A-Z |head -c 8)
            sed -i "s/\"server_port.*/\"server_port\":${app},/g" config_$app.json
            sed -i "s/\"password.*/\"password\":\"${passwd}\",/g" config_$app.json
        fi
        setsid ss-server -c /etc/shadowsocks-libev/config_$app.json -u > /dev/null 2>&1 &
        echo "$app $passwd"
    else
        cd /etc/shadowsocks-libev
        if [ ! -f config_$app.json ];then
            cp config.json config_$app.json
            passwd=$(head -c 100 /dev/urandom | tr -dc a-z0-9A-Z |head -c 8)
            sed -i "s/\"server_port.*/\"server_port\":${app},/g" config_$app.json
            sed -i "s/\"password.*/\"password\":\"${passwd}\",/g" config_$app.json
        fi
        setsid ss-server -c /etc/shadowsocks-libev/config_$app.json -u > /dev/null 2>&1 &
        echo "$app $passwd"
    fi
    ps aux | grep "shadowsocks-libev" | grep "config" | grep -v "grep"
}

function status_ss()
{
    echo "check status of ss..."
    ps aux | grep "shadowsocks.json" | grep -v "grep"
}

function status_ss_server()
{
    echo "check status of ss-server..."
    ps aux | grep "shadowsocks-libev" | grep "config" | grep -v "grep"
}


if [ $# -lt 1 ];then
    usage
fi
behavior="$1"
target="$2"

if [ "$behavior" == "deploy" ];then
    if [ "$target" == "ss" ];then
        stop_firewall
        deploy_shadowsocks
        deploy_bbr
    elif [ "$target" == "ss-server" ];then
        stop_firewall
        deploy_shadowsocks_libev
        deploy_bbr
    else
        usage $behavior
    fi

elif [ "$behavior" == "start" ];then
    if [ "$target" == "ss" ];then
        stop_ss
        start_ss
    elif [ "$target" == "ss-server" ];then
        app=$3
        stop_ss_server $app
        start_ss_server $app
    else
        usage $behavior
    fi
elif [ "$behavior" == "stop" ];then
    if [ "$target" == "ss" ];then
        stop_ss
    elif [ "$target" == "ss-server" ];then
        app=$3
        stop_ss_server $app
    else
        usage $behavior
    fi
elif [ "$behavior" == "status" ];then
    if [ "$target" == "ss" ];then
        status_ss
    elif [ "$target" == "ss-server" ];then
        status_ss_server
    else
        usage $behavior
    fi

else
    usage
fi
cd $WORKSPACE

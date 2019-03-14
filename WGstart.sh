#!/usr/bin/env bash

function blue {
    echo -e " \033[34;01m $1 \033[0m"
}
function green {
    echo -e " \033[32;01m $1 \033[0m"
}
function red {
    echo -e " \033[31;01m $1 \033[0m"
}
function yellow {
    echo -e " \033[33;01m $1 \033[0m"
}


# 检查系统版本
function checkconf {
    clear
    yellow "检查 wireguard 配置文件~~"
    if [ $(ls /etc/wireguard/ |wc -l) -eq 1 ]
    then
        wgconfname=$(ls /etc/wireguard/|head -1|awk -F.conf '{print $1}')
        chmod 600 /etc/wireguard/${wgconfname}.conf 2>&1
        green "OK!"
    else
        red "wireguard 配置文件出错，请检查配置文件是否放入指定位置，或者存在多个配置文件！！"
        exit 1
    fi
    echo
    sleep 1s
}


# 停止wg-quick脚本启动的服务
function stopwg-quick {
    wgstatus=$(systemctl status wg-quick@${wgconfname} 2>&1|grep "active (exited)")
    if [ -n "$(wg 2>&1)" ] && [ -z "${wgstatus}" ]
    then
        yellow "存在由 wg-quick 脚本启动的服务，将其关闭！"
        wg-quick down ${1} 2>&1
    fi
}


# 启动服务
function startservice {
    checkconf
    stopwg-quick ${wgconfname}
    green "启动 Wireguard 服务 wg-quick@${wgconfname}！"
    systemctl restart wg-quick@${wgconfname}
    green "OK！"
    sleep 1s
    wg
    echo
    green "将 Wireguard 服务 wg-quick@${wgconfname} 设为开机启动！"
    systemctl enable wg-quick@${wgconfname}
    green "OK！"
}


# 停止服务
function stopservice {
    wgconfname=$(wg |grep interface|awk '{print $2}')
    if [ -n "${wgconfname}" ]
    then
        stopwg-quick ${wgconfname}
        if [ -n "${wgstatus}" ]
        then
        yellow "将 Wireguard 服务 wg-quick@${wgconfname} 停止！"
        systemctl stop wg-quick@${wgconfname}
        green "OK！"
        fi
    else
        red "服务 wg-quick@${wgconfname} 没有运行！"
    fi  
}


# 取消开机启动
function disableservice {
    wgconfname=$(wg |grep interface|awk '{print $2}')
    if [ -n "${wgconfname}" ]
    then
        yellow "取消服务 wg-quick@${wgconfname} 开机启动设置！！"
        systemctl disable wg-quick@${wgconfname}
        green "OK！"
    else
        checkconf
        yellow "取消服务 wg-quick@${wgconfname} 开机启动设置！！"
        systemctl disable wg-quick@${wgconfname}
        green "OK！"
    fi  

}


# 菜单
function menu {
    clear
    green "~~ScoutV2 Wireguard 服务脚本~~"
    echo
    green "1. 启动&重启WG服务"
    green "2. 停止WG服务"
    green "3. 取消开机启动"
    yellow "0. 退出脚本"
    echo
    read -e -p "  请输入数字:" num
    case "$num" in
    1)
    startservice
    ;;
    2)
    stopservice
    ;;
    3)
    disableservice
    ;;
    0)
    exit 1
    ;;
    *)
    red "请输入正确数字！！"
    sleep 2s
    menu
    ;;
    esac
}

menu
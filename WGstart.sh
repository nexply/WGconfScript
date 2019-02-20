#!/usr/bin/env bash

function blue {
    echo -e "\033[34;01m $1 \033[0m"
}
function green {
    echo -e "\033[32;01m $1 \033[0m"
}
function red {
    echo -e "\033[31;01m $1 \033[0m"
}
function yellow {
    echo -e "\033[33;01m $1 \033[0m"
}


# 检查密钥配置文件
function checkconf {
    yellow "检查 SSH 密钥 $1 是否存在~~"
    if [ -e "/root/.ssh/$1" ]
    then
        chmod 644 /root/.ssh/$1 2>&1
    else
        red "SSH 密钥文件不存在，请检查"
    fi
    echo
    sleep 1s
}


# 检查系统版本
function checksys {
    clear
    if [ -n "$(grep Raspbian /etc/*release)" ]
    then
        blue "系统为 Raspbian"
        echo
        checkconf "authorized_keys"
        yellow "检查 wireguard 配置文件~~"
        if [ $(ls /etc/wireguard|wc -l) -eq 1 ]
        then
            wgconfname=$(ls /etc/wireguard/|head -1|awk -F. '{print $1}')
            chmod 600 /etc/wireguard/${wgconfname}.conf 2>&1
        else
            red "wireguard 配置文件出错，请检查"
            exit 1
        fi
        echo
        sleep 1s
    elif [ -n "$(grep CentOS /etc/*release)" ]
    then
        blue "系统为 CentOS"
        checkconf "id_rsa"
        yellow "检查 wireguard 配置文件~~"
        wgconfname="wg0"
        if [ -e /etc/wireguard/${wgconfname}.conf ]
        then
            chmod 600 /etc/wireguard/${wgconfname}.conf 2>&1
        else
            red "wireguard 配置文件出错，请检查"
            exit 1
        fi
        echo
        sleep 1s
    else
        red "未检测到系统！！"
    fi
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
    checksys
    stopwg-quick ${wgconfname}
    systemctl restart wg-quick@${wgconfname}
    sleep 1s
    wg
    echo
    green "将 Wireguard 服务 wg-quick@${wgconfname} 设为开机启动！"
    systemctl enable wg-quick@${wgconfname}
    echo
    green "done"
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
    else
        checksys
        yellow "取消服务 wg-quick@${wgconfname} 开机启动设置！！"
        systemctl disable wg-quick@${wgconfname}
    fi  

}


# 菜单
function menu {
    clear
    green "~~ScoutV2 Wireguard 服务脚本~~"
    echo
    green " 1. 启动&重启WG服务"
    green " 2. 停止WG服务"
    green " 3. 取消开机启动"
    yellow " 0. 退出脚本"
    echo
    read -e -p "请输入数字:" num
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
    clear
    red "请输入正确数字"
    sleep 2s
    menu
    ;;
    esac
}

menu
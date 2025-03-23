#!/bin/bash

X() {
    local Y=$1 
    local CMD=$2  
    local O=("▖" "▘" "▝" "▗") 
    local i=0  

    printf "[ ] %s" "$Y"

    eval "$CMD" > /dev/null 2>&1 &
    local PID=$!  

    while kill -0 "$PID" 2>/dev/null; do
        printf "\r[%s] %s" "${O[i]}" "$Y"
        i=$(( (i + 1) % 4 ))  
        sleep 0.1
    done

    wait "$PID"
    local EXIT_CODE=$?

    printf "\r                       \r"
    if [[ $EXIT_CODE -eq 0 ]]; then
        printf "[\033[0;32mOK\033[0m] %s\n" "$Y"
    else
        printf "[\033[0;31mNO\033[0m] %s\n" "$Y"
    fi
}

U=$(whoami)
V=$(echo "$U" | tr '[:upper:]' '[:lower:]')
W="$V.serv00.net"
A1="/home/$U/domains/$W"
A2="$A1/public_nodejs"
B1="$A2/public"
A3="https://g.sjy0216.cloudns.ch/clone/serv00"

echo "请选择类型："
echo "1. 本机"
echo "2. 屏蔽gost"
read -p "请输入选择(1 或 2): " choice

if [[ "$choice" -eq 1 ]]; then
    DEPENDENCIES="dotenv basic-auth express"
    TZ_MODIFIED=0
    if [[ "$(date +%Z)" != "CST" ]]; then
        export TZ='Asia/Shanghai'
        echo "export TZ='Asia/Shanghai'" >> ~/.profile
        source ~/.profile
        TZ_MODIFIED=1
    fi
    echo "开始进行 本机配置"
    echo " ———————————————————————————————————————————————————————————— "
    X "删除 默认域名" "cd && devil www del \"$W\""
    X "删除 域名文件" "rm -rf $A1"
    X "创建 类型域名" "devil www add \"$W\" nodejs /usr/local/bin/node22"

    cd "$A2" && npm init -y > /dev/null 2>&1

    X "安装 环境依赖" "npm install $DEPENDENCIES"

    echo "下载 配置文件"
    TEMP_REPO_PATH="/home/$U/repo"  # 使用绝对路径

    # 下载文件到临时目录
    git clone -b nogost $A3 "$TEMP_REPO_PATH"
    if [[ -d "$TEMP_REPO_PATH/single" ]]; then
        echo "移动配置文件到目标目录..."
        mv "$TEMP_REPO_PATH"/single/* "$A2/"
    else
        echo "配置文件下载失败或路径不存在"
        exit 1
    fi
    echo "下载执行文件"

    wget -O- https://github.com/go-gost/gost/releases/download/v3.0.0/gost_3.0.0_freebsd_amd64.tar.gz | tar xzv gost
    wget -O- https://github.com/maomaocris/serv00/releases/download/2.1.0/cftun_freebsd_amd64.tar.gz | tar xzv cftun

elif [[ "$choice" -eq 2 ]]; then
    # 确认 start.sh 文件是否存在
    cd $A2
    if [ ! -f "start.sh" ]; then
        echo "start.sh 文件不存在，请检查路径。"
        exit 1
    fi

    # 屏蔽 (注释) 与 gost 相关的逻辑
    sed -i '/if pgrep -x gost > \/dev\/null/ s/^/#/' start.sh
    sed -i '/then/ s/^/#/' start.sh
    sed -i '/echo "gost 已经运行"/ s/^/#/' start.sh
    sed -i '/else/ s/^/#/' start.sh
    sed -i '/echo "启动 gost..."/ s/^/#/' start.sh
    sed -i '/nohup .\/gost -L socks5:\/\/:12345 >/dev\/null 2>&1 &/ s/^/#/' start.sh
    sed -i '/fi/ s/^/#/' start.sh

    echo "start.sh 中与 gost 相关的部分已被屏蔽！"
fi

if [[ "$choice" -eq 1 ]]; then

    echo ""
    echo " ┌───────────────────────────────────────────────────┐ "
    echo " │ 【 恭 喜 】  本机 部署已完成                  │ "
    echo " ├───────────────────────────────────────────────────┤ "
    echo " │  地址：                                       │ "
    printf " │  → %-46s │\n" "https://$W/"
    echo " └───────────────────────────────────────────────────┘ "
    echo ""

else

    echo ""
    echo " ┌───────────────────────────────────────────────────┐ "
    echo " │ 【 恭 喜 】  gost不会启动了                  │ "
    echo " ├───────────────────────────────────────────────────┤ "
    echo " │                   gost不会启动了                   │ "
    echo " ├───────────────────────────────────────────────────┤ "
    echo " │  服务地址：                                       │ "
    printf " │  → %-46s │\n" "https://$W/"
    echo " └───────────────────────────────────────────────────┘ "
    echo ""
fi

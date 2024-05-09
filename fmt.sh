#!/bin/bash

# 检查 ipkg 是否已安装
if ! command -v ipkg &> /dev/null
then
    echo -e "\033[31;1mipkg not detected, attempting to install...\033[0m"
    wget http://ipkg.nslu2-linux.org/feeds/optware/syno-i686/cross/unstable/syno-i686-bootstrap_1.2-7_i686.xsh
    chmod +x syno-i686-bootstrap_1.2-7_i686.xsh
    sh syno-i686-bootstrap_1.2-7_i686.xsh
    ipkg update
    if ! command -v ipkg &> /dev/null
    then
        echo -e "\033[31;1mUnable to install ipkg [X]\033[0m"
        exit 1
    fi
fi
echo -e "\033[32;1mipkg detected [√]\033[0m"

# 检查 smartctl 是否已安装
if ! command -v smartctl &> /dev/null
then
    echo -e "\033[31;1msmartctl not detected, attempting to install...\033[0m"
    ipkg install smartmontools
    if ! command -v smartctl &> /dev/null
    then
        echo -e "Unable to install smartctl [\033[31;1mX\033[0m]"
        exit 1
    fi
fi
echo -e "smartctl detected [\033[32;1m√\033[0m]"

# 打印表头
echo "Filesystem | Mounted | Temperature Celsius | Info"

# 使用df命令获取文件系统和挂载点信息
df -h | awk 'NR>1 {print $1, $6}' | while read -r line; do
    # 从行中提取文件系统和挂载点
    filesystem=$(echo $line | awk '{print $1}')
    mounted=$(echo $line | awk '{print $2}')

    # 只在/dev/sd*和/dev/nvme*设备上运行smartctl命令
    if [[ $filesystem == /dev/sd* ]] || [[ $filesystem == /dev/nvme* ]]; then
        output=$(smartctl -a -d sat $filesystem)
        temperature=$(echo "$output" | grep -i 'Temperature_Celsius' | awk '{print $10}')

        # 根据温度设置颜色和信息
        if (( temperature < 50 )); then
            echo -e "$filesystem | $mounted | $temperature°C | \033[1;32mNormal temperature range\033[0m"
        elif (( temperature >= 50 && temperature < 60 )); then
            echo -e "$filesystem | $mounted | $temperature°C | \033[1;33mHigh temperature, may affect hard disk life\033[0m"
        else
            echo -e "$filesystem | $mounted | $temperature°C | \033[1;31mExtreme temperature, risk of hard disk damage\033[0m"
        fi
    fi
done

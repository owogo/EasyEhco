#!/bin/bash
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
#	Github: https://github.com/owogo/easyehco
#=================================================================
ehco_conf_path="/etc/ehco/config.json"
raw_conf_path="/etc/ehco/rawconf"
red='\033[0;31m'
plain='\033[0m'

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Font_color_suffix="\033[0m"
#确保本脚本在ROOT下运行
[[ $EUID -ne 0 ]] && echo -e "[${red}错误${plain}]请以ROOT运行本脚本！" && exit 1

check_sys(){
	echo "现在开始检查你的系统是否支持"
	#判断是什么Linux系统
	if [[ -f /etc/redhat-release ]]; then
		release="Centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="Debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="Ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="Centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="Debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="Ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="Centos"
	fi
	
	#判断Linux系统的具体版本和位数
	if [[ -s /etc/redhat-release ]]; then
		version=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1`
	else
		version=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1`
	fi
	bit=`uname -m`
	if [[ ${bit} = "x86_64" ]]; then
		bit="amd64"
	else
		bit="arm"
	fi
	
	#判断内核版本
	kernel_version=`uname -r | awk -F "-" '{print $1}'`
	kernel_version_full=`uname -r`
	net_congestion_control=`cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}'`
	net_qdisc=`cat /proc/sys/net/core/default_qdisc | awk '{print $1}'`
	kernel_version_r=`uname -r | awk '{print $1}'`
	echo "系统版本为: $release $version $bit 内核版本为: $kernel_version_r"
	
	if [ $release = "Centos" ]
	then
		yum -y install wget		
                sysctl_dir="/usr/lib/systemd/system/"
		full_sysctl_dir=${sysctl_dir}"ehco.service"
	elif [ $release = "Debian" ]
	then
		apt-get install wget	
                sysctl_dir="/etc/systemd/system/"
		full_sysctl_dir=${sysctl_dir}"ehco.service"
	elif [ $release = "Ubuntu" ]
	then
		apt-get install wget		
                sysctl_dir="/lib/systemd/system/"
		full_sysctl_dir=${sysctl_dir}"ehco.service"
	else
		echo -e "[${red}错误${plain}]不支持当前系统"
		exit 1
	fi
}

function checknew() {
  checknew=$(ehco -V 2>&1 | awk '{print $2}')
  check_new_ver
  echo "你的ehco版本为:""$checknew"""
  echo -n 是否更新\(y/n\)\:
  read checknewnum
  if test $checknewnum = "y"; then
    cp -r /etc/ehco /tmp/
    Install_ct
    rm -rf /etc/ehco
    mv /tmp/ehco /etc/
    systemctl restart ehco.service
  else
    exit 0
  fi
}

function check_new_ver() {
  ct_new_ver=$(wget --no-check-certificate -qO- -t2 -T3 https://git.googleone.workers.dev/repos/ehco1996/ehco/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g')
  if [[ -z ${ct_new_ver} ]]; then
    ct_new_ver"1.1.1"
    echo -e "${Error} ehco 最新版本获取失败，正在下载v${ct_new_ver}版"
  else
    echo -e "${Info} ehco 目前最新版本为 ${ct_new_ver}"
  fi
}
function check_file() {
  if test ! -d "$sysctl_dir"; then
    mkdir $sysctl_dir
    chmod -R 777 $sysctl_dir
  fi
}
function check_nor_file() {
  check_sys
  rm -rf "$(pwd)"/ehco
  rm -rf "$(pwd)"/ehco.service
  rm -rf "$(pwd)"/config.json
  rm -rf /etc/ehco
  rm -rf $full_sysctl_dir
  rm -rf /usr/bin/ehco
}
 function Install_ct() {
  check_nor_file
  check_file
  check_sys
  check_new_ver
  rm -rf ehco_"$ct_new_ver"_linux_"$bit"
  wget  --no-check-certificate https://ghproxy.com/https://github.com/Ehco1996/ehco/releases/download/v"$ct_new_ver"/ehco_"$ct_new_ver"_linux_"$bit" -O ehco
  chmod +x ehco
  mv ehco /usr/bin
  wget --no-check-certificate https://ghproxy.com/https://raw.githubusercontent.com/owogo/easyehco/master/ehco.service && mv ehco.service $sysctl_dir
  mkdir /etc/ehco && wget --no-check-certificate https://ghproxy.com/https://raw.githubusercontent.com/owogo/easyehco/master/config.json && mv config.json /etc/ehco
  systemctl daemon-reload
  systemctl start ehco.service
  systemctl enable ehco.service
  systemctl restart ehco.service
  echo ""
  clear
  echo "------------------------------"
  if test -a /usr/bin/ehco -a $full_sysctl_dir -a /etc/ehco/config.json; then
    echo "ehco安装成功"
    rm -rf "$(pwd)"/ehco
    rm -rf "$(pwd)"/ehco.service
    rm -rf "$(pwd)"/config.json
  else
    echo "ehco没有安装成功"
    rm -rf "$(pwd)"/ehco
    rm -rf "$(pwd)"/ehco.service
    rm -rf "$(pwd)"/config.json
    rm -rf "$(pwd)"/ehco.sh
  fi
}
function Uninstall_ct() {
  rm -rf /usr/bin/ehco
  rm -rf $full_sysctl_dir
  rm -rf /etc/ehco
  rm -rf "$(pwd)"/ehco.sh
  echo "ehco已经成功删除"
}
function Start_ct() {
  systemctl start ehco.service
  echo "已启动"
}
function Stop_ct() {
  systemctl stop ehco.service
  echo "已停止"
}
function Restart_ct() {
  rm -rf /etc/ehco/config.json
  confstart
  writeconf
  conflast
  systemctl restart ehco.service
  echo "已重读配置并重启"
}
function read_protocol() {
  echo -e "请问您要设置哪种功能: "
  echo -e "-----------------------------------"
  echo -e "[1] tcp+udp流量转发, 不加密"
  echo -e "说明: 一般设置在国内中转机上"
  echo -e "-----------------------------------"
  echo -e "[2] 加密隧道流量转发"
  echo -e "说明: 用于转发原本加密等级较低的流量, 一般设置在国内中转机上"
  echo -e "     选择此协议意味着你还有一台机器用于接收此加密流量, 之后须在那台机器上配置协议[3]进行对接"
  echo -e "-----------------------------------"
  echo -e "[3] 解密由ehco传输而来的流量并转发"
  echo -e "说明: 对于经由ehco加密中转的流量, 通过此选项进行解密并转发给本机的代理服务端口或转发给其他远程机器"
  echo -e "      一般设置在用于接收中转流量的国外机器上"
  echo -e "-----------------------------------"
  read -p "请选择: " numprotocol

  if [ "$numprotocol" == "1" ]; then
    flag_a="nonencrypt"
  elif [ "$numprotocol" == "2" ]; then
    encrypt
  elif [ "$numprotocol" == "3" ]; then
    decrypt
  else
    echo "type error, please try again"
    exit
  fi
}

function encrypt() {
  echo -e "请问您要设置的转发传输类型: "
  echo -e "-----------------------------------"
  echo -e "[1] ws隧道"
  echo -e "[2] wss隧道"
  echo -e "[3] mwss隧道"
  echo -e "注意: 同一则转发，中转与落地传输类型必须对应！"
  echo -e "-----------------------------------"
  read -p "请选择转发传输类型: " numencrypt

  if [ "$numencrypt" == "1" ]; then
    flag_a="encryptws"
  elif [ "$numencrypt" == "2" ]; then
    flag_a="encryptwss"
  elif [ "$numencrypt" == "3" ]; then
    flag_a="encryptmwss"
  else
    echo "type error, please try again"
    exit
  fi
}

function decrypt() {
  echo -e "请问您要设置的解密传输类型: "
  echo -e "-----------------------------------"
  echo -e "[1] ws"
  echo -e "[2] wss"
  echo -e "[3] mwss"
  echo -e "注意: 同一则转发，中转与落地传输类型必须对应！"
  echo -e "-----------------------------------"
  read -p "请选择解密传输类型: " numdecrypt

  if [ "$numdecrypt" == "1" ]; then
    flag_a="decryptws"
  elif [ "$numdecrypt" == "2" ]; then
    flag_a="decryptwss"
  elif [ "$numdecrypt" == "3" ]; then
    flag_a="decryptmwss"
  else
    echo "type error, please try again"
    exit
  fi
}

function method() {
  if [ $i -ge 1 ]; then
    if [ "$is_encrypt" == "nonencrypt" ]; then
      echo "   \"listen\": \"0.0.0.0:$s_port\",
      \"listen_type\": \"raw\",
      \"transport_type\": \"raw\",
      \"tcp_remotes\": [\"$d_ip:$d_port\"],
      \"udp_remotes\": [\"$d_ip:$d_port\"]" >>$ehco_conf_path
    elif [ "$is_encrypt" == "encryptws" ]; then
      echo "   \"listen\": \"0.0.0.0:$s_port\",
      \"listen_type\": \"raw\",
      \"transport_type\": \"ws\",
      \"tcp_remotes\": [\"ws://$d_ip:$d_port\"],
      \"udp_remotes\": [\"ws://$d_ip:$d_port\"]" >>$ehco_conf_path
    elif [ "$is_encrypt" == "encryptwss" ]; then
      echo "   \"listen\": \"0.0.0.0:$s_port\",
      \"listen_type\": \"raw\",
      \"transport_type\": \"wss\",
      \"tcp_remotes\": [\"wss://$d_ip:$d_port\"],
      \"udp_remotes\": [\"wss://$d_ip:$d_port\"]" >>$ehco_conf_path
    
	elif [ "$is_encrypt" == "encryptmwss" ]; then
      echo "   \"listen\": \"0.0.0.0:$s_port\",
      \"listen_type\": \"raw\",
      \"transport_type\": \"mwss\",
      \"tcp_remotes\": [\"wss://$d_ip:$d_port\"],
      \"udp_remotes\": [\"wss://$d_ip:$d_port\"]" >>$ehco_conf_path
    
    elif [ "$is_encrypt" == "decryptws" ]; then
      echo "   \"listen\": \"0.0.0.0:$s_port\",
      \"listen_type\": \"ws\",
      \"transport_type\": \"raw\",
      \"tcp_remotes\": [\"$d_ip:$d_port\"],
      \"udp_remotes\": [\"$d_ip:$d_port\"]" >>$ehco_conf_path
    elif [ "$is_encrypt" == "decryptwss" ]; then
      echo "   \"listen\": \"0.0.0.0:$s_port\",
      \"listen_type\": \"wss\",
      \"transport_type\": \"raw\",
      \"tcp_remotes\": [\"$d_ip:$d_port\"],
      \"udp_remotes\": [\"$d_ip:$d_port\"]" >>$ehco_conf_path
    elif [ "$is_encrypt" == "decryptmwss" ]; then
      echo "   \"listen\": \"0.0.0.0:$s_port\",
      \"listen_type\": \"mwss\",
      \"transport_type\": \"raw\",
      \"tcp_remotes\": [\"$d_ip:$d_port\"],
      \"udp_remotes\": [\"$d_ip:$d_port\"]" >>$ehco_conf_path
    else
      echo "config error"
    fi
  else
    echo "config error"
    exit
  fi
}

function read_s_port() {
  echo -e "请问你要将本机哪个端口接收到的流量进行转发?"
  read -p "请输入: " flag_b
}
function read_d_ip() {
  echo -e "------------------------------------------------------------------"
  echo -e "请问你要将本机从${flag_b}接收到的流量转发向哪个IP或域名?"
  echo -e "注: IP既可以是[远程机器/当前机器]的公网IP, 也可是以本机本地回环IP(即127.0.0.1)"
  echo -e "具体IP地址的填写, 取决于接收该流量的服务正在监听的IP"
  read -p "请输入: " flag_c
}
function read_d_port() {
  echo -e "------------------------------------------------------------------"
  echo -e "请问你要将本机从${flag_b}接收到的流量转发向${flag_c}的哪个端口?"
  read -p "请输入: " flag_d
}
function writerawconf() {
  echo $flag_a"/""$flag_b""#""$flag_c""#""$flag_d" >>$raw_conf_path
}
function rawconf() {
  read_protocol
  read_s_port
  read_d_ip
  read_d_port
  writerawconf
}
function eachconf_retrieve() {
  d_server=${trans_conf#*#}
  d_port=${d_server#*#}
  d_ip=${d_server%#*}
  flag_s_port=${trans_conf%%#*}
  s_port=${flag_s_port#*/}
  is_encrypt=${flag_s_port%/*}
}
function confstart() {
  echo "{
  \"web_port\": 9000,
  \"web_token\": \"\",
  \"enable_ping\": false,

  \"relay_configs\": [ " >>$ehco_conf_path
}
function multiconfstart() {
  echo "        {   ">>$ehco_conf_path
}
function conflast() {
  echo "   ]
}" >>$ehco_conf_path
}

function multiconflast() {
  if [ $i -eq $count_line ]; then
    echo "           }" >>$ehco_conf_path
  else
    echo "           }," >>$ehco_conf_path
  fi
}

function writeconf() {
  count_line=$(awk 'END{print NR}' $raw_conf_path)
  for ((i = 1; i <= $count_line; i++)); do
    if [ $i -eq 1 ]; then
      trans_conf=$(sed -n "${i}p" $raw_conf_path)
      eachconf_retrieve
      multiconfstart
      method
      multiconflast
    elif [ $i -gt 1 ]; then
      trans_conf=$(sed -n "${i}p" $raw_conf_path)
      eachconf_retrieve
      multiconfstart
      method
      multiconflast
    fi
  done
}
function show_all_conf() {
  echo -e "                      EHCO 配置                        "
  echo -e "--------------------------------------------------------"
  echo -e "序号|方法\t    |本地端口\t|目的地地址:目的地端口"
  echo -e "--------------------------------------------------------"

  count_line=$(awk 'END{print NR}' $raw_conf_path)
  for ((i = 1; i <= $count_line; i++)); do
    trans_conf=$(sed -n "${i}p" $raw_conf_path)
    eachconf_retrieve

    if [ "$is_encrypt" == "nonencrypt" ]; then
      str="不加密中转"
    elif [ "$is_encrypt" == "encryptws" ]; then
      str="  ws隧道 "
    elif [ "$is_encrypt" == "encryptwss" ]; then
      str=" wss隧道 "
    elif [ "$is_encrypt" == "encryptwss" ]; then
      str=" mwss隧道 "
    elif [ "$is_encrypt" == "decryptws" ]; then
      str="  ws解密 "
    elif [ "$is_encrypt" == "decryptwss" ]; then
      str=" wss解密 "
    elif [ "$is_encrypt" == "decryptmwss" ]; then
      str=" mwss解密 "
    else
      str=""
    fi

    echo -e " $i  |$str  |$s_port\t|$d_ip:$d_port"
    echo -e "--------------------------------------------------------"
  done
}

cron_restart() {
  echo -e "------------------------------------------------------------------"
  echo -e "ehco定时重启任务: "
  echo -e "-----------------------------------"
  echo -e "[1] 配置ehco定时重启任务"
  echo -e "[2] 删除ehco定时重启任务"
  echo -e "-----------------------------------"
  read -p "请选择: " numcron
  if [ "$numcron" == "1" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "ehco定时重启任务类型: "
    echo -e "-----------------------------------"
    echo -e "[1] 每？小时重启"
    echo -e "[2] 每日？点重启"
    echo -e "-----------------------------------"
    read -p "请选择: " numcrontype
    if [ "$numcrontype" == "1" ]; then
      echo -e "-----------------------------------"
      read -p "每？小时重启: " cronhr
      echo "0 0 */$cronhr * * ? * systemctl restart ehco.service" >>/etc/crontab
      echo -e "定时重启设置成功！"
    elif [ "$numcrontype" == "2" ]; then
      echo -e "-----------------------------------"
      read -p "每日？点重启: " cronhr
      echo "0 0 $cronhr * * ? systemctl restart ehco.service" >>/etc/crontab
      echo -e "定时重启设置成功！"
    else
      echo "type error, please try again"
      exit
    fi
  elif [ "$numcron" == "2" ]; then
    sed -i "/ehco/d" /etc/crontab
    echo -e "定时重启任务删除完成！"
  else
    echo "type error, please try again"
    exit
  fi
}

echo && echo -e "            ehco 一键安装配置脚本
  功能: 1.tcp+udp不加密转发, 2.中转机加密转发, 3.落地机解密对接转发
  帮助文档：https://github.com/owogo/EasyEhco
 ${Green_font_prefix}1.${Font_color_suffix} 安装 ehco
 ${Green_font_prefix}2.${Font_color_suffix} 更新 ehco
 ${Green_font_prefix}3.${Font_color_suffix} 卸载 ehco
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 启动 ehco
 ${Green_font_prefix}5.${Font_color_suffix} 停止 ehco
 ${Green_font_prefix}6.${Font_color_suffix} 重启 ehco
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 新增ehco转发配置
 ${Green_font_prefix}8.${Font_color_suffix} 查看现有ehco配置
 ${Green_font_prefix}9.${Font_color_suffix} 删除一则ehco配置
————————————
 ${Green_font_prefix}10.${Font_color_suffix} ehco定时重启配置

————————————" && echo
read -e -p " 请输入数字 [1-10]:" num
case "$num" in
1)
  Install_ct
  ;;
2)
  checknew
  ;;
3)
  Uninstall_ct
  ;;
4)
  Start_ct
  ;;
5)
  Stop_ct
  ;;
6)
  Restart_ct
  ;;
7)
  rawconf
  rm -rf /etc/ehco/config.json
  confstart
  writeconf
  conflast
  systemctl restart ehco.service
  echo -e "配置已生效，当前配置如下"
  echo -e "--------------------------------------------------------"
  show_all_conf
  ;;
8)
  show_all_conf
  ;;
9)
  show_all_conf
  read -p "请输入你要删除的配置编号：" numdelete
  if echo $numdelete | grep -q '[0-9]'; then
    sed -i "${numdelete}d" $raw_conf_path
    rm -rf /etc/ehco/config.json
    confstart
    writeconf
    conflast
    systemctl restart ehco.service
    echo -e "配置已删除，服务已重启"
  else
    echo "请输入正确数字"
  fi
  ;;
10)
  cron_restart
  ;;
*)
  echo "请输入正确数字"
  ;;
esac

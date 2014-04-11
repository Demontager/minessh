#!/bin/bash
# author: demontager
# website: nixtalk.com
#********Secton for configuration**************************************#

# 1. Define mining server ip and port, uncomment(remove trailing #) or add aditional if required

miners[0]="192.168.1.1 -p 22"
miners[1]="192.168.1.2 -p 22"
miners[2]="192.168.1.3 -p 22"
#miners[3]="000.00.00.00 -p 22"
#miners[4]="000.00.00.00 -p 22"

# 2. Define your mining pools. Change "url", "user", "pass" fields. Unlimited pools could be specified, two as example only. 
#************************POOL CONFIG***********************************#
config=$(cat << 'EOF'
{
"pools" : [
          {
            "url" : "stratum+tcp://server:3336",
            "user" : "User",
            "pass" : "x"
          },
          {
            "url" : "stratum+tcp://server1:3336",
            "user" : "User",
            "pass" : "x"
          }
]
EOF
)
# 3. Enable email notification ? YES/NO, default: NO
notify="YES"

# 4. Define mail settings to get notified. Leave smpt and port as default if gmail used.
email="your_id@gmail.com"
password="your_email_password"
smtp="smtp.gmail.com"
port="587"
#***************Configuration END**************************************#

bamt() {
pool() {
pool_ex() {
echo "$config"|ssh root@$host 'cat - > /tmp/pool.tmp && sed -n "/]/{:a;n;/}/b;p;ba}" /etc/bamt/cgminer.conf > /tmp/cgminer.conf.tmp \
&& cat /tmp/pool.tmp /tmp/cgminer.conf.tmp > /etc/bamt/cgminer.conf && echo "}" >> /etc/bamt/cgminer.conf \
&& rm /tmp/pool.tmp /tmp/cgminer.conf.tmp'	
ssh root@$host 'mine restart'
echo ""
echo -n -e "${RED_TEXT}Mining config changed for:${NORMAL} "&& echo $host|awk '{print $1}'
echo ""
}
echo ""
COUNTER=-1
for host in "${miners[@]}"; do
  let COUNTER=COUNTER+1 
  echo -n -e "[$COUNTER]${MENU} Miner IP:${NORMAL} " && echo $host|awk '{print $1}'
  echo ""
done    
echo -n -e "${MENU}Choose mining server: [0 1 2.. or type all] ${NORMAL}"
echo ""
echo -n  -e "${MENU}[Enter] back to Main Menu${NORMAL}"
echo ""
read miner	
echo "$miner" | grep '^[0-9][0-9]*$' >/dev/null 2>&1
if [ `echo $?` = 0 ] || [ $miner = 'all' ]; then
  if [ $miner = 'all' ]; then
    for host in "${miners[@]}"; do  
      pool_ex
    done
    menu_list
  elif [ $miner != 'all' ]; then
    host="${miners[$miner]}"
    pool_ex
    menu_list  
  else
    main_menu
  fi
else
   main_menu
fi  
}
colors() {
#***************Colors*************************************************#
NORMAL=`echo "\033[m"`
MENU=`echo "\033[36m"` #Blue
NUMBER=`echo "\033[33m"` #yellow
FGRED=`echo "\033[41m"`
RED_TEXT=`echo "\033[31m"`
ENTER_LINE=`echo "\033[33m"`	
}

menu_list() {
echo -e "${MENU}[Enter] Back to menu [Q]uit?${NORMAL}"
read input
while [ input != '' ]; do
      if [[ $input = "" ]]; then 
            clear
            main_menu;
    else
       case $input in
         q|Q)  exit 0 
            ;;
          x)exit;
              ;;

           \n)exit;
              ;;
            *) echo "Invalid opt, going back to Main Menu...";
            sleep 2
            main_menu;
        esac
      fi
done
   
}

status() {
for server in "${miners[@]}"; do
  echo ""
  echo -e "${MENU}*********Miner IP: `echo $server|awk '{print $1}'`${NORMAL}"
  echo ""
  ssh root@$server '/opt/bamt/viewgpu'
  done
  echo ""	
menu_list
}

viewpool() {
echo ""
COUNTER=-1
for host in "${miners[@]}"; do
  let COUNTER=COUNTER+1 
  echo -n -e "[$COUNTER]${MENU} Miner IP:${NORMAL} " && echo $host|awk '{print $1}'
  echo ""
done  
echo -n -e "${MENU}Choose mining server [0 1 2.. ]${NORMAL}"
echo ""
read miner
clear; echo -n "Mining server:  " && echo ${miners[$miner]}|awk '{print $1}'
echo ""
ssh root@${miners[$miner]} 'cat /etc/bamt/cgminer.conf'	
menu_list
}

reboot() {
echo ""
COUNTER=-1
for host in "${miners[@]}"; do
  let COUNTER=COUNTER+1 
  echo -n -e "[$COUNTER]${MENU} Miner IP:${NORMAL} " && echo $host|awk '{print $1}'
  echo ""
done  

reboot_ex() {	
ssh root@$host 'sync && /sbin/coldreboot'
echo -n "Reboot signal sent to: "&& echo $host|awk '{print $1}'
echo ""
}
echo -n -e "${MENU}Choose mining server: [0 1 2.. or type all] ${NORMAL}" 
echo ""
echo -n  -e "${MENU}[Enter] back to Main Menu${NORMAL}"
echo ""
read miner	
echo "$miner" | grep '^[0-9][0-9]*$' >/dev/null 2>&1
if [ `echo $?` = 0 ] || [ $miner = 'all' ]; then
  if [ $miner = 'all' ]; then
    echo "Sure to reboot all mining servers ? [y/n] "
      read choice
      if [ $choice = 'y' ] || [ $choice = 'yes' ]; then  
        for host in "${miners[@]}"; do   
          reboot_ex
        done
        menu_list
      elif [ $choice = 'n' ] || [ $choice = 'no' ]; then
        main_menu
      else
        main_menu
     fi
elif [ $miner != 'all' ]; then 
  host="${miners[$miner]}"
  reboot_ex
  menu_list  
  fi
else
  main_menu
fi 
}

ssh_config() {
echo -e "
${RED_TEXT}************************Read carefully!***************************************${NORMAL}

 Now you will be promted to create public and private keys on localhost
 This procedure required to create non-password authentication from current machine to your miner(s)
 Do it only once unless mining server/localhost changed.
 Do not enter any passphrases just hit 'Enter'.
 Also accept default storage for id_rsa identification to get script procceed (hit 'Enter')
 While connecting to each mining server enter valid ssh passwords.

${RED_TEXT}******************************************************************************${NORMAL}"

id_add() {
for host in "${miners[@]}"; do 
  echo -e "${MENU}*********Miner IP: `echo $host|awk '{print $1}'`${NORMAL}"
  if [ `uname -n` != 'bamt-miner' ] && [ `uname -n` != 'bamt' ] && [ `uname -n` != 'smos' ]; then
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@$host
  else
    ssh-copy-id -i ~/.ssh/id_rsa.pub "root@$host"
  fi
done
echo ""
echo -e "${MENU}Check for errors and repeat procedure if required${NORMAL}"
sleep 2
}

echo -e "${MENU}Press any key to continue or [Escape] to back in Main Menu${NORMAL}"
read -s -n1  key
if [ $'\e' = $key ]; then  
  main_menu
else
  true
  clear
fi

if [ -e ~/.ssh/id_rsa.pub ]; then
  echo ""
  echo -e "${MENU}You already got existing public rsa key skippig..${NORMAL}"
  echo ""
  sleep 2
  id_add
  menu_list
else
  ssh-keygen
  id_add
  menu_list
fi  
}

ssh_login() {
echo ""
COUNTER=-1
for host in "${miners[@]}"; do
  let COUNTER=COUNTER+1 
  echo -n -e "[$COUNTER]${MENU} Miner IP:${NORMAL} " && echo $host|awk '{print $1}'
  echo ""
  echo ""
done  
echo -n -e "${MENU}Choose mining server [0 1 2.. ]${NORMAL}"
echo ""
echo -n  -e "${MENU}[Enter] back to Main Menu${NORMAL}"
echo ""
read miner
if [ -n "$miner" ]; then
  clear; echo -n "Mining server:  " && echo ${miners[$miner]}|awk '{print $1}'
  echo ""
  ssh -t root@${miners[$miner]} "cd /etc/bamt ; ls; bash"
  menu_list
else 
  main_menu
fi	
}

miner_change(){
echo ""
COUNTER=-1
for host in "${miners[@]}"; do
  let COUNTER=COUNTER+1 
  echo -n -e "[$COUNTER]${MENU} Miner IP:${NORMAL}" && echo $host|awk '{print $1}'
  echo ""
done 
miner_ex() {
cat <<'EOF' | ssh root@$host 'cat - > /etc/bamt/switch.sh && chmod +x /etc/bamt/switch.sh && touch /root/.hushlogin'
#!/bin/bash
#
#
TERM=xterm
export TERM

troky(){
if [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ] && [ -e "/etc/bamt/current.troky" ]; then
  echo "Already troky"
  echo ""
elif [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ]; then
  mine stop
  rm "/opt/miners/cgminer-3.7.2-kalroth" && rm "/etc/bamt/cgminer.conf"; rm /opt/miners/sgminer-4.1.0-troky/cgminer 2>/dev/null
  ln -s /opt/miners/sgminer-4.1.0-troky /opt/miners/cgminer-3.7.2-kalroth && ln -s /opt/miners/sgminer-4.1.0-troky/sgminer /opt/miners/sgminer-4.1.0-troky/cgminer
  ln -s /etc/bamt/sgminer-troky.conf /etc/bamt/cgminer.conf; rm /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.troky
  mine start
elif [ ! -L "/etc/bamt/cgminer.conf" ] && [ ! -L "/opt/miners/cgminer-3.7.2-kalroth" ]; then
  mine stop
  mv /opt/miners/cgminer-3.7.2-kalroth /opt/miners/cgminer-3.7.2-kalroth.orig && mv /etc/bamt/cgminer.conf /etc/bamt/cgminer.conf.scrypt
  rm /opt/miners/sgminer-4.1.0-troky/cgminer 2>/dev/null; ln -s /opt/miners/sgminer-4.1.0-troky/sgminer /opt/miners/sgminer-4.1.0-troky/cgminer
  ln -s /opt/miners/sgminer-4.1.0-troky /opt/miners/cgminer-3.7.2-kalroth && ln -s /etc/bamt/sgminer-troky.conf /etc/bamt/cgminer.conf
  rm  /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.troky
  mine start
fi    
}

sph(){
if [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ] && [ -e "/etc/bamt/current.sph" ]; then
  echo "Already sph"
  echo ""
elif [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ]; then
  mine stop
  rm "/opt/miners/cgminer-3.7.2-kalroth" && rm "/etc/bamt/cgminer.conf"; rm /opt/miners/sgminer-4.1.0-sph/cgminer 2>/dev/null
  ln -s /opt/miners/sgminer-4.1.0-sph /opt/miners/cgminer-3.7.2-kalroth && ln -s /opt/miners/sgminer-4.1.0-sph/sgminer /opt/miners/sgminer-4.1.0-sph/cgminer
  ln -s /etc/bamt/sgminer-sph.conf /etc/bamt/cgminer.conf; rm /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.sph
  mine start
elif [ ! -L "/etc/bamt/cgminer.conf" ] && [ ! -L "/opt/miners/cgminer-3.7.2-kalroth" ]; then
  mine stop
  mv /opt/miners/cgminer-3.7.2-kalroth /opt/miners/cgminer-3.7.2-kalroth.orig && mv /etc/bamt/cgminer.conf /etc/bamt/cgminer.conf.scrypt
  rm /opt/miners/sgminer-4.1.0-sph/cgminer 2>/dev/null; ln -s /opt/miners/sgminer-4.1.0-sph/sgminer /opt/miners/sgminer-4.1.0-sph/cgminer
  ln -s /opt/miners/sgminer-4.1.0-sph /opt/miners/cgminer-3.7.2-kalroth && ln -s /etc/bamt/sgminer-sph.conf /etc/bamt/cgminer.conf
  rm  /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.sph
  mine start
fi    
}

vertminer(){
if [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ] && [ -e "/etc/bamt/current.vertminer" ]; then
  echo "Already vertminer"
  echo ""
elif [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ]; then
  mine stop
  rm "/opt/miners/cgminer-3.7.2-kalroth" && rm "/etc/bamt/cgminer.conf"; rm /opt/miners/vertminer-0.5.2-thekev/cgminer 2>/dev/null
  ln -s /opt/miners/vertminer-0.5.2-thekev /opt/miners/cgminer-3.7.2-kalroth && ln -s /opt/miners/vertminer-0.5.2-thekev/vertminer /opt/miners/vertminer-0.5.2-thekev/cgminer
  ln -s /etc/bamt/vertminer.conf /etc/bamt/cgminer.conf; rm /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.vertminer
  mine start
elif [ ! -L "/etc/bamt/cgminer.conf" ] && [ ! -L "/opt/miners/cgminer-3.7.2-kalroth" ]; then
  mine stop
  mv /opt/miners/cgminer-3.7.2-kalroth /opt/miners/cgminer-3.7.2-kalroth.orig && mv /etc/bamt/cgminer.conf /etc/bamt/cgminer.conf.scrypt
  rm /opt/miners/vertminer-0.5.2-thekev/cgminer 2>/dev/null; ln -s /opt/miners/vertminer-0.5.2-thekev/vertminer /opt/miners/vertminer-0.5.2-thekev/cgminer
  ln -s /opt/miners/vertminer-0.5.2-thekev /opt/miners/cgminer-3.7.2-kalroth && ln -s /etc/bamt/vertminer.conf /etc/bamt/cgminer.conf
  rm  /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.vertminer
  mine start
fi    
}

custom() {
if [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ] && [ -e "/etc/bamt/current.custom" ]; then
  echo "Already custom"
  echo ""
elif [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ]; then
  mine stop
  rm "/opt/miners/cgminer-3.7.2-kalroth" && rm "/etc/bamt/cgminer.conf"
  ln -s /opt/miners/custom /opt/miners/cgminer-3.7.2-kalroth
  ln -s /etc/bamt/custom.conf /etc/bamt/cgminer.conf; rm  /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.custom
  mine start
elif [ ! -L "/etc/bamt/cgminer.conf" ] && [ ! -L "/opt/miners/cgminer-3.7.2-kalroth" ]; then
  mine stop
  mv /opt/miners/cgminer-3.7.2-kalroth /opt/miners/cgminer-3.7.2-kalroth.orig && mv /etc/bamt/cgminer.conf /etc/bamt/cgminer.conf.scrypt
  ln -s /opt/miners/custom /opt/miners/cgminer-3.7.2-kalroth && ln -s /etc/bamt/custom.conf /etc/bamt/cgminer.conf
  rm  /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.custom
  mine start
fi    
}

custom1() {
if [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ] && [ -e "/etc/bamt/current.custom1" ]; then
  echo "Already custom1"
  echo ""
elif [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ]; then
  mine stop
  rm "/opt/miners/cgminer-3.7.2-kalroth" && rm "/etc/bamt/cgminer.conf"
  ln -s /opt/miners/custom1 /opt/miners/cgminer-3.7.2-kalroth
  ln -s /etc/bamt/custom1.conf /etc/bamt/cgminer.conf; rm  /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.custom1
  mine start
elif [ ! -L "/etc/bamt/cgminer.conf" ] && [ ! -L "/opt/miners/cgminer-3.7.2-kalroth" ]; then
  mine stop
  mv /opt/miners/cgminer-3.7.2-kalroth /opt/miners/cgminer-3.7.2-kalroth.orig && mv /etc/bamt/cgminer.conf /etc/bamt/cgminer.conf.scrypt
  ln -s /opt/miners/custom1 /opt/miners/cgminer-3.7.2-kalroth && ln -s /etc/bamt/custom1.conf /etc/bamt/cgminer.conf
  rm  /etc/bamt/current* 2>/dev/null; touch /etc/bamt/current.custom1
  mine start
fi    
}

scrypt() {
if [ -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ -L "/etc/bamt/cgminer.conf" ] && [ -e "/opt/miners/cgminer-3.7.2-kalroth.orig" ]; then
  mine stop
  rm /opt/miners/cgminer-3.7.2-kalroth && rm /etc/bamt/cgminer.conf
  mv /opt/miners/cgminer-3.7.2-kalroth.orig /opt/miners/cgminer-3.7.2-kalroth && mv /etc/bamt/cgminer.conf.scrypt /etc/bamt/cgminer.conf
  rm  /etc/bamt/current* 2>/dev/null && touch /etc/bamt/current.scrypt
  mine start	
elif [ ! -L "/opt/miners/cgminer-3.7.2-kalroth" ] && [ ! -L "/etc/bamt/cgminer.conf" ]; then
    rm  /etc/bamt/current* 2>/dev/null && touch /etc/bamt/current.scrypt
    echo "Already scrypt"
fi
}

msg(){
echo "Choose miner scrypt/sjane"
}
  
case "$1" in
        scrypt)
                scrypt
                ;;
        vertminer)
                vertminer        
                 ;;
         troky)
                troky
                ;;
         sph)
                 sph
                 ;;
        custom)
                custom        
                 ;;
        custom1)
                custom1        
                 ;;                            
           *)
                msg
                exit 1
                ;;
esac

EOF
ssh root@$host "$( cat << EOT
/etc/bamt/switch.sh $algo
rm /root/.hushlogin
EOT
)"
echo ""
echo -n -e "${RED_TEXT}Mining software changed on: ${NORMAL}"&& echo $host|awk '{print $1}'
echo ""
} 
echo -e "${MENU}Choose mining server: [0 1 2... or all] ${NORMAL}"
read miner
clear
echo "$miner" | grep '^[0-9][0-9]*$' >/dev/null 2>&1
if [ `echo $?` = 0 ] || [ $miner = 'all' ]; then
  if [ $miner != 'all' ];then
    echo -n "Mining server: " && echo ${miners[$miner]}|awk '{print $1}'
  else 
      echo "Mining server: all" 
  fi 
echo -e "
[1] cgminer-3.7.2-kalroth 
[2] sgminer-4.1.0-sph 
[3] sgminer-4.1.0-troky
[4] vertminer-0.5.2-thekev
[5] custom
[6] custom1
[7] Back to Main menu or hit Enter

${MENU}Select mining software [1 2 3...] ${NORMAL}"
read n

case $n in
    1) algo=scrypt;;
    2) algo=sph;;
    3) algo=troky;;
    4) algo=vertminer;;
    5) algo=custom;;
    6) algo=custom1;;
    7) main_menu;;
    *) echo "Invalid option, going back to Main Menu..."
    sleep 2
    main_menu;;
esac
clear
  if [ $miner = 'all' ]; then  
    for host in "${miners[@]}"; do   
      miner_ex
    done
    menu_list
  elif [ $miner != 'all' ]; then 
    host="${miners[$miner]}"
    miner_ex
    menu_list  
  fi
else 
   echo "Invalid mining server"
fi
}

monitor() {
monitor_ex(){
SESSIONNAME="monitoring"

tmux has-session -t $SESSIONNAME > /dev/null
if [ $? != 0 ]; then  
  tmux new-session -s $SESSIONNAME -n monitor -d
  for host in "${miners[@]}"; do
    tmux send-keys "ssh root@$host" C-m
    tmux send-keys 'screen -r' 'C-m'
    tmux split-window -t $SESSIONNAME:0 -h
   done
fi
tmux select-layout tiled
tmux send-keys '/tmp/control.sh' 'C-m'
tmux select-window -t $SESSIONNAME:0
tmux attach -t $SESSIONNAME
}

control_ex() {
controlf="/tmp/control.sh"
cat << EOF > "$controlf"
#!/bin/bash
printf "\033c"
echo ""
echo "************Press Enter or any key to back in Main Menu"
read input
tmux kill-server
EOF
chmod +x "$controlf"
monitor_ex
}
dpkg -l|grep tmux
if [ `echo $?` != 0 ]; then
echo ""
echo "Seems tmux not installed, it is required for real time monitoring
You will be promted for root password to install tmux automatically
"
sleep 5
sudo apt-get --yes --force-yes install tmux
control_ex
else
control_ex
fi
}

mailfunc() {
get_log() {
cat > ~/.msmtprc <<EOF	
defaults
    tls on
    # the path below may need to be adjusted
    tls_trust_file /etc/ssl/certs/ca-certificates.crt

account gmail
    from none@gmail.com
    host $smtp
    port $port
    auth plain
    user $email

account default : gmail
EOF
chmod 600 ~/.msmtprc
echo 'set sendmail="/usr/bin/msmtp"' > ~/.mailrc	
cat > ~/.netrc <<EOF
machine $smtp
    login $email
    password $password
EOF
get_ip=$(cat << EOF
#!/bin/bash
INTERFACE=\$(cat /proc/net/arp | grep -m 1 -v Device | awk '{print $6}')
IPL=\$(/sbin/ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | cut -d' ' -f1 | tr -d '[:blank:]')
echo \$IPL > /tmp/get_ip.txt
sed -i 's/127.0.0.1//' /tmp/get_ip.txt
EOF
)
DATE=`date +%d-%b-%Y`
echo "$DATE" > /tmp/mail.txt
echo "" >> /tmp/mail.txt
for host in "${miners[@]}"; do
  echo "" >> /tmp/mail.txt
  echo "$get_ip"|ssh root@$host 'cat - > /tmp/get_ip.sh && chmod +x /tmp/get_ip.sh && /tmp/get_ip.sh'
  real_ip=$(ssh root@$host cat /tmp/get_ip.txt)
  echo "********Miner IP: `echo $real_ip`" >> /tmp/mail.txt
  output=$(ssh root@$host tail -n 5 /etc/bamt/autoRebooter.log 2>/dev/null)
  output1=$(ssh root@$host /opt/bamt/viewgpu)
  echo "$output1" >> /tmp/mail.txt
  echo "" >> /tmp/mail.txt
  echo "autoRebooter.log" >> /tmp/mail.txt
  echo "$output" >> /tmp/mail.txt
  unset output
  unset output1
  echo -n -e "${MENU} Miner IP:${NORMAL}" && echo "$real_ip logs sent to $email"
done
res=`cat /tmp/mail.txt`
echo "$res" | mail -s "Mining stat" "$email"
echo ""  
menu_list
}
if [ "$notify" = 'YES' ]; then
  dpkg -l|grep msmtp 1> /dev/null
  if [ `echo $?` != 0 ]; then
    echo ""
    echo "Seems msmtp not installed, it is required for mail functionality
You will be promted for root password to install msmtp automatically"
    sleep 5
    sudo apt-get --yes --force-yes install msmtp
    clear
    echo "Sending logs standby..."
    echo ""
    get_log
  else
    get_log
  fi
else
  echo ""
  echo -e "${ENTER_LINE}First enable email notification then you may use this feature${RED_TEXT}
${MENU}Press [Enter] or any key to back in Main Menu${NORMAL}"
  read -s -n1  key
  if [ -z $key ]; then  
    main_menu
  else
    main_menu
  fi  
fi
}

main_menu() {
show_menu(){
	colors
    echo -e "${MENU}************Main Menu***********************${NORMAL}"
    echo -e "${MENU}**${NUMBER} 1)${MENU} Show mining servers status ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 2)${MENU} Change pool config for selected miner  ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 3)${MENU} View pool config for selected miner ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 4)${MENU} Reboot mining server ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 5)${MENU} Switch mining software e.g. scrypt/scrypt-jane/scrypt-n.. ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 6)${MENU} Configure mining server SSH authentication ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 7)${MENU} SSH login to mining server ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 8)${MENU} Send logs to e-mail ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 9)${MENU} Real time monitoring ${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${ENTER_LINE}Please pick a menu option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"
    read opt
}

option_picked() {
    COLOR='\033[01;31m' # bold red
    RESET='\033[00;00m' # normal white
    MESSAGE=${@:-"${RESET}Error: No message passed"}
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

clear
show_menu
while [ opt != '' ]
    do
    if [[ $opt = "" ]]; then 
            exit;
    else
        case $opt in
        1)  clear
            option_picked "Show mining servers status";
            status; 
            ;;

        2) clear;
            option_picked "Change pool config for selected miner";
            pool;
            show_menu;
            ;;

        3) clear;
            option_picked "View pool config of selected miner";
            viewpool;
            show_menu;
            ;;

        4) clear;
            option_picked "Reboot mining server";
            reboot;
            show_menu;
            ;;
        5) clear;
            option_picked "Switch mining software e.g. scrypt/scrypt-jane/scrypt-n..";
            miner_change;
            show_menu;
            ;;
         6) clear;
            option_picked "Configure mining server SSH authentication";
            ssh_config;
            show_menu;
            ;;
         7) clear;
            option_picked "SSH login to mining server";
            ssh_login;
            show_menu;
            ;;   
         8) clear;
            option_picked "Send logs to e-mail";
            mailfunc
            main_menu     
            ;;
         9) clear;
            option_picked "Real time monitoring";
            monitor
            main_menu     
            ;;     
          x)exit;
            ;;

          \n)exit;
            ;;

        *)clear;
        option_picked "[Wrong action!] Pick an option from the menu 1 2 3..";
        show_menu;
        ;;
    esac
fi
done
}
main_menu
}

cron() {
mail_cron() {
mailrc='set sendmail="/usr/bin/msmtp"'
netrc=$(cat << EOF
machine $smtp
    login $email
    password $password
EOF
)	
msmtprc=$(cat << EOF
defaults
    tls on
    # the path below may need to be adjusted
    tls_trust_file /etc/ssl/certs/ca-certificates.crt

account gmail
    from none@gmail.com
    host $smtp
    port $port
    auth plain
    user $email

account default : gmail
EOF
)
mail_error=$(cat << EOF
#!/bin/bash
echo `date +%d-%b-%Y\ \ time\ %H:%M` > /tmp/mail_error.txt
echo "" >> /tmp/mail_error.txt
INTERFACE=\$(cat /proc/net/arp | grep -m 1 -v Device | awk '{print $6}')
IPL=\$(/sbin/ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | cut -d' ' -f1 | tr -d '[:blank:]')
echo \$IPL > /tmp/ip.txt
sed -i 's/127.0.0.1//' /tmp/ip.txt
IP=\$(cat /tmp/ip.txt)
echo "----------------MINER IP: \$IP" >> /tmp/mail_error.txt
echo "" >> /tmp/mail_error.txt
echo "autoRebooter.log" >> /tmp/mail_error.txt
tail -n 3 /etc/bamt/autoRebooter.log >> /tmp/mail_error.txt
echo "" >> /tmp/mail_error.txt
echo "viewgpu" >> /tmp/mail_error.txt
/opt/bamt/viewgpu >> /tmp/mail_error.txt
result=\$(cat /tmp/mail_error.txt)
echo "\$result" | mail -s "[FAIL]Mining stat IP:\$IP" "$email"
EOF
)

for host in "${miners[@]}"; do
  out=$(ssh root@$host dpkg -l|grep msmtp)
  if [ -z "$out" ]; then
    echo "$mailrc"|ssh root@$host 'cat - > /root/.mailrc'
    echo "$netrc"|ssh root@$host 'cat - > /root/.netrc'
    echo "$msmtprc"|ssh root@$host 'cat - > /root/.msmtprc'
    echo "$mail_error"|ssh root@$host 'cat - > /tmp/mail.sh && chmod +x /tmp/mail.sh'
    ssh root@$host 'DEBIAN_FRONTEND=noninteractive apt-get --yes --force-yes install msmtp bsd-mailx >/dev/null && chmod 600 /root/.msmtprc'
  else
    echo "$mailrc"|ssh root@$host 'cat - > /root/.mailrc'
    echo "$netrc"|ssh root@$host 'cat - > /root/.netrc'
    echo "$msmtprc"|ssh root@$host 'cat - > /root/.msmtprc'
    echo "$mail_error"|ssh root@$host 'cat - > /tmp/mail.sh && chmod +x /tmp/mail.sh && chmod 600 /root/.msmtprc'
  fi
done
}
	
if_sick () {
for server in "${miners[@]}"; do	
cat <<'EOF' | ssh root@$server 'cat - > /tmp/api.py && python /tmp/api.py devs > /tmp/if_sick.txt'	
import socket
import json
import sys

def linesplit(socket):
	buffer = socket.recv(4096)
	done = False
	while not done:
		more = socket.recv(4096)
		if not more:
			done = True
		else:
			buffer = buffer+more
	if buffer:
		return buffer

api_command = sys.argv[1].split('|')

if len(sys.argv) < 3:
	api_ip = '127.0.0.1'
	api_port = 4028
else:
	api_ip = sys.argv[2]
	api_port = sys.argv[3]

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect((api_ip,int(api_port)))
if len(api_command) == 2:
	s.send(json.dumps({"command":api_command[0],"parameter":api_command[1]}))
else:
	s.send(json.dumps({"command":api_command[0]}))

response = linesplit(s)
response = response.replace('\x00','')
response = json.loads(response)
if api_command[0]=="devs":
    j=1
    for i in response["DEVS"]:
        print j, i["Status"]
        j+=1 
else:
    print response
s.close()
EOF
done	
}
	
if_temp() {	
for server in "${miners[@]}"; do	
cat <<'EOF' | ssh root@$server 'cat - > /tmp/cardcheck.sh && chmod +x /tmp/cardcheck.sh && /tmp/cardcheck.sh'
targetMinTemp=57
sickres="/tmp/if_sick.txt"
i=0
(/opt/bamt/viewgpu | awk '{ print $2; }' | cut -c -2 > /tmp/viewgpu)
sleep 3
array=(`cat /tmp/viewgpu`)
if [ ${#array[@]} -eq 0 ]; then
  echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` viewgpu command failed to run, rebooting" >>  /etc/bamt/autoRebooter.log
  sync && /sbin/coldreboot &
  sleep 30
  echo s > /proc/sysrq-trigger
  sleep 10
  echo b > /proc/sysrq-trigger
elif [ ${#array[@]} -ne 0 ]; then
   INTERFACE=`cat /proc/net/arp | grep -m 1 -v Device | awk '{print $6}'`
   echo "----------------MINER IP:`/sbin/ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | cut -d' ' -f1 | tr -d '[:blank:]'`"
   echo "`/opt/bamt/viewgpu`"
   echo ""
fi
for temp in ${array[@]}; do
  if [ $temp -lt $targetMinTemp ]; then
    echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` card number $i has stopped, its current temp is $temp, coldrebooting" >> /etc/bamt/autoRebooter.log
    sync && /sbin/coldreboot &
    sleep 30
    echo s > /proc/sysrq-trigger
    sleep 10
    echo b > /proc/sysrq-trigger
  fi
i=$(($i+1))
done
cards=(`cat $sickres|awk '{print $2}'`)
egrep -w 'Sick|Dead|NoStart' $sickres
status=`echo $?`
if [ "$status" = 0 ]; then
  for card in ${cards[@]}; do
    echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` card number $i is ${cards[$card]} , coldrebooting" >> /etc/bamt/autoRebooter.log
    sync && /sbin/coldreboot &
    sleep 30
    echo s > /proc/sysrq-trigger
    sleep 10
    echo b > /proc/sysrq-trigger
  i=$(($i+1))
  done
fi
EOF
done
}

if_temp_mail() {	
for server in "${miners[@]}"; do	
cat <<'EOF' | ssh root@$server 'cat - > /tmp/cardcheck.sh && chmod +x /tmp/cardcheck.sh && /tmp/cardcheck.sh'
targetMinTemp=57
sickres="/tmp/if_sick.txt"
i=0
(/opt/bamt/viewgpu | awk '{ print $2; }' | cut -c -2 > /tmp/viewgpu)
sleep 3
array=(`cat /tmp/viewgpu`)
if [ ${#array[@]} -eq 0 ]; then
  echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` viewgpu command failed to run, rebooting" >>  /etc/bamt/autoRebooter.log
  /tmp/mail.sh
  sync && /sbin/coldreboot &
  sleep 30
  echo s > /proc/sysrq-trigger
  sleep 10
  echo b > /proc/sysrq-trigger
elif [ ${#array[@]} -ne 0 ]; then
   INTERFACE=`cat /proc/net/arp | grep -m 1 -v Device | awk '{print $6}'`
   echo "----------------MINER IP:`/sbin/ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | cut -d' ' -f1 | tr -d '[:blank:]'`"
   echo "`/opt/bamt/viewgpu`"
   echo ""
fi
for temp in ${array[@]}; do
  if [ $temp -lt $targetMinTemp ]; then
    echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` card number $i has stopped, its current temp is $temp, coldrebooting" >> /etc/bamt/autoRebooter.log
    /tmp/mail.sh   
    sync && /sbin/coldreboot &
    sleep 30
    echo s > /proc/sysrq-trigger
    sleep 10
    echo b > /proc/sysrq-trigger
  fi
i=$(($i+1))
done
cards=(`cat $sickres|awk '{print $2}'`)
egrep -w 'Sick|Dead|NoStart' $sickres
status=`echo $?`
if [ "$status" = 0 ]; then
  for card in ${cards[@]}; do
    echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` card number $i is ${cards[$card]} , coldrebooting" >> /etc/bamt/autoRebooter.log
    /tmp/mail.sh
    sync && /sbin/coldreboot &
    sleep 30
    echo s > /proc/sysrq-trigger
    sleep 10
    echo b > /proc/sysrq-trigger
  i=$(($i+1))
  done
fi
EOF
done
}

if [ "$notify" = 'YES' ]; then
  mail_cron
  if_sick
  if_temp_mail
else 
  if_sick
  if_temp
fi  
}

if [ $# -eq 0 ]; then
  bamt
elif [ "$1" = 'cron' ]; then
  cron
else 
  echo 'Unknow parameter, use "cron" to check all miners, e.g. ./minessh cron' 
fi

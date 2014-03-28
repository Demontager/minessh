#!/bin/bash
# author: demontager
# website: nixtalk.com
#*******Secton for configuration****************************************

# 1. Define mining server ip and port, uncomment(remove trailing #) or add aditional if required

miners[0]="192.168.1.1 -p 22"
miners[1]="192.168.1.2 -p 22"
miners[2]="192.168.1.3 -p 22"
#miners[3]="000.00.00.00 -p 22"
#miners[4]="000.00.00.00 -p 22"

# 2. Define your mining pools. 
#************************POOL CONFIG************************************

pool() {
pool_ex() {
cat <<'EOF' | ssh root@$host 'cat - > /tmp/pool.tmp && sed -n "/]/{:a;n;/}/b;p;ba}" /etc/bamt/cgminer.conf > /tmp/cgminer.conf.tmp \
&& cat /tmp/pool.tmp /tmp/cgminer.conf.tmp > /etc/bamt/cgminer.conf && echo "}" >> /etc/bamt/cgminer.conf \
&& rm /tmp/pool.tmp /tmp/cgminer.conf.tmp'	
{
"pools" : [
        {
                "url" : "stratum+tcp://mine.coinshift.com:3333",
                "user" : "1PGgybf5QbCTohCoRgEA4Q5ZSLhpSsg8cn",
                "pass" : "x"
        
        },
        {
                "url" : "stratum+tcp://eu.wafflepool.com:3333",
                "user" : "1PGgybf5QbCTohCoRgEA4Q5ZSLhpSsg8cn",
                "pass" : "x"

        }
]
EOF
ssh root@$host 'mine restart'
echo ""
echo -n -e "${RED_TEXT}Mining config changed for:${NORMAL} "&& echo $host|awk '{print $1}'
echo ""
}

#***************Configuration END***************************************
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
#****************Colors*************************************************
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

cron() {
for server in "${miners[@]}"; do	
cat <<'EOF' | ssh root@$server 'cat - > /etc/bamt/cardcheck.sh && chmod +x /etc/bamt/cardcheck.sh && /etc/bamt/cardcheck.sh'
targetMinTemp=52
i=0
(/opt/bamt/viewgpu | awk '{ print $2; }' | cut -c -2 > /tmp/viewgpu)
sleep 5
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
EOF
done
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

ssh_server() {
echo -e "
${RED_TEXT}************************Read carefully!***************************************${NORMAL}

 Now you will be promted to create public and private keys on Localhost
 This procedure required to create non-password authentication from current machine to your miner(s)
 Do it only once unless mining server/localhost changed.
 Do not enter any passphrases just hit 'Enter'.
 Also accept default storage for id_rsa identification to get script procceed (hit 'Enter')
 While connecting to each mining server enter valid ssh passwords.

${RED_TEXT}******************************************************************************${NORMAL}"

sleep 12
ssh-keygen
for host in "${miners[@]}"; do
  ssh-copy-id -i ~/.ssh/id_rsa.pub root@$host
done
echo ""
echo "Check for errors and repeat procedure if required"
echo ""
sleep 5
menu_list
}

ssh_login() {
echo ""
COUNTER=-1
for host in "${miners[@]}"; do
  let COUNTER=COUNTER+1 
  echo -n -e "[$COUNTER]${MENU} Miner IP:${NORMAL} " && echo $host|awk '{print $1}'
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
    echo -e "${MENU}**${NUMBER} 8)${MENU} Real time monitoring ${NORMAL}"
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
            ssh_server;
            show_menu;
            ;;
         7) clear;
            option_picked "SSH login to mining server";
            ssh_login;
            show_menu;
            ;;   
         8) clear;
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

if [ $# -eq 0 ]; then
main_menu
else
  cron
fi

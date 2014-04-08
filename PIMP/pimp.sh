#!/bin/bash
# author: demontager
# website: nixtalk.com
#*******Secton for configuration***************************************#

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
#***************Configuration END**************************************#

pimp() {
pool() {
pool_ex() {	
echo "$config"|ssh root@$host 'cat - > /tmp/pool.tmp && sed -n "/]/{:a;n;/}/b;p;ba}" /opt/ifmi/cgminer.conf > /tmp/cgminer.conf.tmp \
&& cat /tmp/pool.tmp /tmp/cgminer.conf.tmp > /opt/ifmi/cgminer.conf && echo "}" >> /opt/ifmi/cgminer.conf \
&& rm /tmp/pool.tmp /tmp/cgminer.conf.tmp'	
ssh root@$host '/etc/init.d/mine restart'
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
  ssh root@$server '/opt/pimp/viewgpu'
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
ssh root@${miners[$miner]} 'cat /opt/ifmi/cgminer.conf'	
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
  ssh-copy-id -i ~/.ssh/id_rsa.pub root@$host
done
echo ""
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
done  
echo -n -e "${MENU}Choose mining server [0 1 2.. ]${NORMAL}"
echo ""
echo -n  -e "${MENU}[Enter] back to Main Menu${NORMAL}"
echo ""
read miner
if [ -n "$miner" ]; then
  clear; echo -n "Mining server:  " && echo ${miners[$miner]}|awk '{print $1}'
  echo ""
  ssh -t root@${miners[$miner]} "cd /opt/ifmi ; ls; bash"
  menu_list
else 
  main_menu
fi	
}

miner_change() {
echo ""
COUNTER=-1
for host in "${miners[@]}"; do
  let COUNTER=COUNTER+1 
  echo -n -e "[$COUNTER]${MENU} Miner IP:${NORMAL}" && echo $host|awk '{print $1}'
  echo ""
done 
miner_ex() {
cat <<'EOF' | ssh root@$host 'cat - > /tmp/switch.sh && chmod +x /tmp/switch.sh && touch /root/.hushlogin'
#!/bin/bash
#
#
TERM=xterm
export TERM

chacha(){
if [ -e "/opt/ifmi/current.chacha" ]; then
  echo "Already Chacha"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"; rm /opt/yacminer/sgminer 2>/dev/null
  ln -s /opt/yacminer /opt/sgminer-4.1.0 && ln -s /opt/yacminer/yacminer /opt/yacminer/sgminer
  ln -s /opt/ifmi/cgminer.chacha.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.chacha
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/yacminer /opt/sgminer-4.1.0 && ln -s /opt/ifmi/cgminer.chacha.conf /opt/ifmi/cgminer.conf
  rm /opt/yacminer/sgminer 2>/dev/null; ln -s /opt/yacminer/yacminer /opt/yacminer/sgminer
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.chacha
  /etc/init.d/mine start
fi    
}

darkcoin(){
if [ -e "/opt/ifmi/current.darkcoin" ]; then
  echo "Already Darkcoin"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"
  ln -s /opt/sph-sgminer /opt/sgminer-4.1.0
  ln -s /opt/ifmi/cgminer.darkcoin.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.darkcoin
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/sph-sgminer /opt/sgminer-4.1.0 && ln -s /opt/ifmi/cgminer.darkcoin.conf /opt/ifmi/cgminer.conf
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.darkcoin
  /etc/init.d/mine start
fi    
}

groestl(){
if [ -e "/opt/ifmi/current.groestl" ]; then
  echo "Already Groestl"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"
  ln -s /opt/sph-sgminer /opt/sgminer-4.1.0
  ln -s /opt/ifmi/cgminer.groestl.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.groestl
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/sph-sgminer /opt/sgminer-4.1.0 && ln -s /opt/ifmi/cgminer.groestl.conf /opt/ifmi/cgminer.conf
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.groestl
  /etc/init.d/mine start
fi    
}

heavy(){
if [ -e "/opt/ifmi/current.heavy" ]; then
  echo "Already heavy"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"; rm /opt/cgminer_heavy/sgminer 2>/dev/null
  ln -s /opt/cgminer_heavy /opt/sgminer-4.1.0 && ln -s /opt/cgminer_heavy/cgminer /opt/cgminer_heavy/sgminer
  ln -s /opt/ifmi/cgminer.heavy.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.heavy
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/cgminer_heavy /opt/sgminer-4.1.0 && ln -s /opt/ifmi/cgminer.heavy.conf /opt/ifmi/cgminer.conf
  rm /opt/cgminer_heavy/сgminer 2>/dev/null; ln -s /opt/cgminer_heavy/cgminer /opt/cgminer_heavy/sgminer
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.heavy
  /etc/init.d/mine start
fi    
}

keccak(){
if [ -e "/opt/ifmi/current.keccak" ]; then
  echo "Already Keccak"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"; rm /opt/cgminer_heavy/sgminer 2>/dev/null
  ln -s /opt/cgminer_heavy /opt/sgminer-4.1.0 && ln -s /opt/cgminer_heavy/cgminer /opt/cgminer_heavy/sgminer
  ln -s /opt/ifmi/cgminer.keccak.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.keccak
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/cgminer_heavy /opt/sgminer-4.1.0 && ln -s /opt/ifmi/cgminer.keccak.conf /opt/ifmi/cgminer.conf
  rm /opt/cgminer_heavy/сgminer 2>/dev/null; ln -s /opt/cgminer_heavy/cgminer /opt/cgminer_heavy/sgminer
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.keccak
  /etc/init.d/mine start
fi    
}

qubit(){
if [ -e "/opt/ifmi/current.qubit" ]; then
  echo "Already Qubit"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"
  ln -s /opt/sph-sgminer /opt/sgminer-4.1.0
  ln -s /opt/ifmi/cgminer.qubit.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.qubit
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/sph-sgminer /opt/sgminer-4.1.0 && ln -s /opt/ifmi/cgminer.qubit.conf /opt/ifmi/cgminer.conf
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.qubit
  /etc/init.d/mine start
fi    
}

jane(){
if [ -e "/opt/ifmi/current.jane" ]; then
  echo "Already jane"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"
  ln -s /opt/sgminer-scryptjane /opt/sgminer-4.1.0
  ln -s /opt/ifmi/cgminer.jane.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.jane
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/sgminer-scryptjane /opt/sgminer-4.1.0 && ln -s /opt/ifmi/cgminer.jane.conf /opt/ifmi/cgminer.conf
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.jane
  /etc/init.d/mine start
fi    
}

scryptn(){
if [ -e "/opt/ifmi/current.scryptn" ]; then
  echo "Already Scrypt-Nfactor"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"
  ln -s /opt/sgminer-4.1.0.orig /opt/sgminer-4.1.0   
  ln -s /opt/ifmi/cgminer.scryptn.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.scryptn
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/ifmi/cgminer.scryptn.conf /opt/ifmi/cgminer.conf
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.scryptn
  /etc/init.d/mine start
fi    
}

custom() {
if [ -e "/opt/ifmi/current.custom" ]; then
  echo "Already custom"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"
  ln -s /opt/custom /opt/sgminer-4.1.0
  ln -s /opt/ifmi/custom.conf /opt/ifmi/cgminer.conf; rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.custom
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/custom /opt/sgminer-4.1.0 && ln -s /opt/ifmi/custom.conf /opt/ifmi/cgminer.conf
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.custom
  /etc/init.d/mine start
fi    
}

custom1() {
if [ -e "/opt/ifmi/current.custom1" ]; then
  echo "Already custom1"
  echo ""
elif [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ]; then
  /etc/init.d/mine stop
  rm "/opt/sgminer-4.1.0" && rm "/opt/ifmi/cgminer.conf"
  ln -s /opt/custom1 /opt/sgminer-4.1.0
  ln -s /opt/ifmi/custom1.conf /opt/ifmi/cgminer.conf; rm /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.custom1
  /etc/init.d/mine start
elif [ ! -L "/opt/ifmi/cgminer.conf" ] && [ ! -L "/opt/sgminer-4.1.0" ]; then
  /etc/init.d/mine stop
  mv /opt/sgminer-4.1.0 /opt/sgminer-4.1.0.orig && mv /opt/ifmi/cgminer.conf /opt/ifmi/cgminer.conf.scrypt
  ln -s /opt/custom1 /opt/sgminer-4.1.0 && ln -s /opt/ifmi/custom1.conf /opt/ifmi/cgminer.conf
  rm  /opt/ifmi/current* 2>/dev/null; touch /opt/ifmi/current.custom1
  /etc/init.d/mine start
fi    
}

scrypt() {
if [ -L "/opt/sgminer-4.1.0" ] && [ -L "/opt/ifmi/cgminer.conf" ] && [ -e "/opt/sgminer-4.1.0.orig" ]; then
  /etc/init.d/mine stop
  rm /opt/sgminer-4.1.0 && rm /opt/ifmi/cgminer.conf
  mv /opt/sgminer-4.1.0.orig /opt/sgminer-4.1.0 && mv /opt/ifmi/cgminer.conf.scrypt /opt/ifmi/cgminer.conf
  rm  /opt/ifmi/current* 2>/dev/null && touch /opt/ifmi/current.scrypt
  /etc/init.d/mine start	
elif [ ! -L "/opt/sgminer-4.1.0" ] && [ ! -L "/opt/ifmi/cgminer.conf" ]; then
   rm  /opt/ifmi/current* 2>/dev/null && touch /opt/ifmi/current.scrypt
   echo "Already scrypt

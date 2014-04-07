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
        scryptn)
                scryptn        
                 ;;
         jane)
                jane
                ;;
         qubit)
                 qubit
                 ;;
        keccak)
                keccak        
                 ;;
        heavy)
                heavy        
                 ;;
        groestl)
                groestl        
                 ;;
        darkcoin)
                darkcoin        
                 ;;
        chacha)
                chacha        
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
/tmp/switch.sh $algo
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
[1] Scrypt   (sgminer-4.1.0) 
[2] Scrypt-Nfactor   (sgminer-4.1.0)
[3] Jane   (sgminer-scryptjane)
[4] Qubit   (sph-sgminer)
[5] SHA3-Keccak   (cgminer_heavy)
[6] Heavy   (cgminer_heavy)
[7] Groestl   (sph-sgminer)
[8] Darkcoin   (sph-sgminer)
[9] Chacha   (yacminer)
[10] custom
[11] custom1
[12] Back to Main menu or hit Enter

${MENU}Select mining software [1 2 3...] ${NORMAL}"
read n

case $n in
    1) algo=scrypt;;
    2) algo=scryptn;;
    3) algo=jane;;
    4) algo=qubit;;
    5) algo=keccak;;
    6) algo=heavy;;
    7) algo=groestl;;
    8) algo=darkcoin;;
    9) algo=chacha;;
    10) algo=custom;;
    11) algo=custom1;;
    12) main_menu;;
    *) echo "Invalid option, going back to Main Menu..."
    sleep 1
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
            ssh_config;
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
main_menu
}

cron() {
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
(/opt/pimp/viewgpu | awk '{ print $2; }' | cut -c -2 > /tmp/viewgpu)
sleep 3
array=(`cat /tmp/viewgpu`)
if [ ${#array[@]} -eq 0 ]; then
  echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` viewgpu command failed to run, rebooting" >>  /opt/ifmi/autoRebooter.log
  sync && /sbin/coldreboot &
  sleep 30
  echo s > /proc/sysrq-trigger
  sleep 10
  echo b > /proc/sysrq-trigger
elif [ ${#array[@]} -ne 0 ]; then
   INTERFACE=`cat /proc/net/arp | grep -m 1 -v Device | awk '{print $6}'`
   echo "----------------MINER IP:`/sbin/ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | cut -d' ' -f1 | tr -d '[:blank:]'`"
   echo "`/opt/pimp/viewgpu`"
   echo ""
fi
for temp in ${array[@]}; do
  if [ $temp -lt $targetMinTemp ]; then
    echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` card number $i has stopped, its current temp is $temp, coldrebooting" >> /opt/ifmi/autoRebooter.log
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
    echo "`date +%m-%d-%Y` `uptime | awk -F, '{sub(".*ge ",x,$1);print $1}'` card number $i is ${cards[$card]} , coldrebooting" >> /opt/ifmi/autoRebooter.log
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
if_sick
if_temp
}

if [ $# -eq 0 ]; then
  pimp
elif [ "$1" = 'cron' ]; then
  cron
else 
  echo 'Unknow parameter, use "cron" to check all miners, e.g. ./minessh cron' 
fi

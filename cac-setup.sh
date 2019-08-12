#!/bin/bash
adr=`echo $(hostname -I | cut -d" " -f 1)` #here should be ip adress
gate=`ip route get 8.8.8.8 | awk '{print $3}'` #gateway ip
iname=`echo $(ip -o link show | sed -rn '/^[0-9]+: en/{s/.: ([^:]*):.*/\1/p}')` #interface name
inet=`netstat -nr | awk 'NR>3 {print $1}'` #network address
mask=`ip  -f inet a show ens5| grep inet| awk '{ print $2}'`
mask_2=`printf $mask | tail -c2` #obtaining netmask in 2 steps
# installing VPN client

yum -y install epel-release
yum -y install openvpn openconnect

# network hook, editing rc.local:

chmod +x /etc/rc.d/rc.local
echo "inserting info in /etc/rc.d/rc.local ..."
echo "ip rule add table 128 from $adr" >> /etc/rc.d/rc.local
echo "ip route add table 128 to $inet/$mask_2 dev $iname" >> /etc/rc.d/rc.local
echo "ip route add table 128 default via $gate" >> /etc/rc.d/rc.local
echo "openvpn --mktun --dev tun1" >> /etc/rc.d/rc.local

echo "Important!!! Correct .bash_profile with propper data"

IFS='' read -r -d '' String <<"EOF"
PASSWD=`cat /usr/local/etc/openconnect/password`

alias connect='/bin/echo $PASSWD | openconnect $@ -b --authgroup=<if_required> --user=<if_required> --no-dtls --interface=tun1 https://<ip_or_url_here>'
alias disconnect='pkill -SIGINT openconnect'
alias status='cat /sys/class/net/tun1/operstate'

echo -e "Usage: \n\t * 'connect' to attach to VPN;\n\t * 'disconnect' to disconnect;\nUse bashrc to edit password/username in case it does not match\n\n\t \n "

if [ $(status) == "up" ]; then
        echo -e "\033[00;32m VPN is UP"
else
        echo -e "\033[01;31m VPN is DOWN"
fi

echo -e "\033[00m"
EOF
echo "Inserting info in .bash_profile ..."
echo "$String" > .bash_profile

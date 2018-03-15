#!/bin/sh
# Auto Setup PPTP VPN Server #
# By Github/Saleh7 #

## How to install a VPN Server (PPTP) on Debian/Ubuntu Linux VPS
## https://vpnreviewer.com/how-to-install-vpn-server-pptp-debian-ubuntu-linux-vps

## PPTPServer
## https://help.ubuntu.com/community/PPTPServer

## client ubuntu setup pptp 
## https://boxpn.com/setup_pptp_ubuntu_14_04.aspx

E=`tput setaf 1`
G=`tput setaf 2`
A=`tput setaf 3`
C=`tput setaf 6`
B=`tput bold`
R=`tput sgr0`

help() {
echo " 
  ${b}${A}# Auto Setup PPTP VPN Server #${R}

Use: pptp.sh ${E}[OPTION]${R}
 ${G}-u${R}, --username  Enter the Username
 ${G}-p${R}, --password  Enter the Password
Password Make sure it's more than ${E}8${R} characters

 Example:${G} sudo bash pptp.sh -u${R} ${E}vpn${R} ${G}-p${R} ${E}mypass${R}

 ${C}Default:${R}${G} sudo bash pptp.sh${R}${C} | Username:yasseraz1988 Pssword:azsx123456${R}

 ------------------------------------
 | Add More Users | Edit a File:    |
 | ${G}sudo nano /etc/ppp/chap-secrets${R}  | 
 ------------------------------------
-
"
}
# check sudo
if [ `id -u` -ne 0 ] 
then
  echo "${B}${E} try with sudo !!${R}"
  exit 0
fi

while [ "$1" != "" ]; do
  case "$1" in
    -u  | --username ) user=$2;shift 2;;
    -p  | --password ) pass=$2;shift 2;;
    -h  | --help )     echo "$(help)";
    exit;shift;break;;
  esac
done

apt-get update
apt-get install pptpd -y
apt-get install curl  -y

CHAR8=$(echo ${#pass})

if [ -z "$pass" ] || [ $CHAR8 -lt 8 ] 
then
  pass="pass1231"
fi

if [ -z "$user" ]
then
   user="vpn01"
fi

cat > /etc/ppp/options.pptpd <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
lock
nobsdcomp 
novj
novjccomp
nologfd
END


cat > /etc/pptpd.conf <<END
option /etc/ppp/options.pptpd
logwtmp
localip 192.168.2.1
remoteip 192.168.2.10-100
END


cat > /etc/ppp/chap-secrets <<END
#client | server | secret | IP addresses
$user     pptpd    $pass      *
END

sed -i '/^exit 0/d' /etc/rc.local

cat >> /etc/rc.local <<END
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -I INPUT -p tcp --dport 1723 -j ACCEPT
iptables -I INPUT  --protocol 47 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -d 0.0.0.0/0 -o eth0 -j MASQUERADE
iptables -I FORWARD -s 192.168.2.0/24 -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j TCPMSS --set-mss 1356
END

sh /etc/rc.local

service pptpd restart
rm -fr pptp.sh
## https://www.ipify.org | API Usage 
IP=`curl -s https://api.ipify.org`

echo "${G}=========================================${R}"
echo "server ip address: $IP"
echo ""
echo "user = $user   pass = $pass"
echo "${G}=========================================${R}"

exit 0

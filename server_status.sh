#!/usr/bin/env bash
tmp=`echo $$_$(date +%Y%m%d%H%M%S)`
trap 'rm .*.${tmp} && exit' 0 1 2 15

#- default inputs
t_server='None'
USER='None'
servers="None"
ssuffix="None"

#- help function
HELP () {
cat << EOM
##############################################################
Program:   $0, Nicolas Celli 2023
Purpose:   Check the usage on selected remote servers

Syntax:
           -u Username for access to servers
           -t Tunnelling server needed as intermediate step to
              reach the destination server (aka proxy server)
           -s list of servers to check, enclosed by quotes,
              space-separated

Notes:     for quicker checks, set default values for the inputs
           in the source code of this program

Options:
           -x common suffix to all server names (OPTIONAL)
Example:
           $0 -u me -s "address.of.server1 address.of.server2 address.of.server3" -t my.tunnel.server

##############################################################

EOM
}

#- read in options
while getopts hu:s:t:x: OPT; do
  case ${OPT} in
    h)  HELP; exit;;
    u)  USER=`echo ${OPTARG}`;;
    s)  servers=`echo ${OPTARG}`;;
    t)  t_server=`echo "${OPTARG}"`;;
    x)  ssuffix=`echo ${OPTARG}`;;
    \?) echo "No correct option given; see help:"; HELP; exit;;
  esac
done

format=" %-10s %s %6s %s %4s %11s\n"

#- check user
if [ ${USER} == "None" ]; then
  echo "please indicate a user, either with -u or by setting it in the source code defaults, exit"
  exit
fi

#- add suffix to servers
if [ ${t_server} == "None" ] || [ ${t_server} == "None${ssuffix}" ]; then
	echo "running the code without proxy specifications"
else
	t_server="${t_server}${ssuffix}"
	echo "running the code trough proxy ${t_server}"
fi

#- gather information on the servers (in parallel)
echo ""
echo "...gathering information from servers..."
echo ""

for server in ${servers}; do
  if [ ! ${ssuffix} == "None" ]; then
		iserver=${server}${ssuffix}
	else
		iserver=${server}
  fi
	if [ ${t_server} == "None" ] || [ ${t_server} == "None${ssuffix}" ]; then
		topt=""
	else
		topt="-J ${USER}@${t_server}"
	fi

	\ssh ${topt} ${USER}@${iserver} '\free -g;\uptime; \grep -c ^processor /proc/cpuinfo' > .serv_${server}.${tmp} &
done

#- wait for processes
wait

#- write out
echo "======================================="
echo "Memory Usage"
echo "---------------------------------------"
for server in ${servers}; do
        umem=`awk 'NR==2{if($3>=1000) printf "%.1fT",$3/1000; else printf "%.0fG",$3;}' .serv_${server}.${tmp}`
        tmem=`awk 'NR==2{if($2>=1000) printf "%.1fT",$2/1000; else printf "%.0fG",$2;}' .serv_${server}.${tmp}`
        printf "${format}" ${server} ":" ${umem} "/" "${tmem}" $(awk 'NR==2{printf "(%.2f%%)\n",$3*100/$2 }' .serv_${server}.${tmp})
done
echo "======================================="
echo "CPU Usage"
echo "---------------------------------------"
for server in ${servers}; do
        ucpu=`awk 'NR==4{print $12}' .serv_${server}.${tmp} | sed 's/,/ /g'`
        tcpu=`awk 'NR==5{print $1}' .serv_${server}.${tmp}`
        printf "${format}" ${server} ":" ${ucpu} "/" "${tcpu}" $(echo "${ucpu} ${tcpu}"| awk '{printf "(%.2f%%)\n",$1/$2*100}')
done

echo "======================================="

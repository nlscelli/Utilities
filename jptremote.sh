#!/usr/bin/env bash
trap "kill 0" SIGINT   #- kill all subshells on exit

#- default inputs
port=8889
d_server='my.fav.server'
t_server='my.fav.proxy'
conda_env='None'
jupyter='jupyter-lab'
USER='None'
jptstop=0


#- help function
HELP () {
cat << EOM
##############################################################
Program:   $0, Nicolas Celli 2022
Purpose:   Run jupyterlab/jupyter notebooks on remote machines

Notes:     You can either close the connection or leave it open:
           the program checks if there is already a matching
           jupyter running on the indicated server and port.
           If so, it will automatically reconnect to it.

Syntax:
           -u Username for access to server
           -s Destination server where to run the jupyter notebook
           -t Tunnelling server needed as intermediate step to
              reach the destination server (aka proxy server)
           -p port on which to open jupyter (default 8889)
           -e anaconda environment from which to open jupyter (if any)
					 -j what notebook to run: either "jupyter-lab" or "jupyter notebook"
              (within quotes)
           -x close remote notebook matching parameters

Example:
           $0 -u me -s my.server.com -t my.tunnel.server -p 8889 -e my_conda

##############################################################

EOM
}

#- read in options
while getopts hs:t:p:e:j:u:x OPT; do
  case ${OPT} in
    h)  HELP; exit;;
    u)  USER=`echo ${OPTARG}`;;
    s)  d_server=`echo ${OPTARG}`;;
    t)  t_server=`echo ${OPTARG}`;;
    p)  port=`echo ${OPTARG}`;;
    e)  conda_env=`echo ${OPTARG}`;;
    j)  jupyter=`echo ${OPTARG}`;;
		x)  jptstop=1;;
    \?) echo "No correct option given; see help:"; HELP; exit;;
  esac
done

echo ""
echo "#==============================================#"
echo "#-   jptremote.sh - remote jupyter sessions   -#"
echo "#-             by Nicolas Celli               -#"
echo "#==============================================#"
echo ""

if [ ${USER} == "None" ]; then
	echo "please indicate a user, either with -u or by setting it in the source code defaults, exit"
	exit
fi

#- if any, enter a conda environment before running the notebook
if [ ! ${conda_env} == "None" ]; then
	conda_comm="conda activate ${conda_env} &&"
else
	conda_comm=""
fi

#- check for which jupyter program to run
if [ ${jupyter} != "jupyter-lab" ] && [ ${jupyter} != "jupyter notebook" ]; then
	echo '-j has to indicate either "jupyter-lab" or "jupyter notebook", exit' && exit
fi

#- build remote command for jupyter
remotecomm="${conda_comm} nohup ${jupyter} --port=${port} --no-browser --ip=0.0.0.0 > jptset.out"

#- check if the port is available
if_port_free=$(\ssh -J ${USER}@${t_server} ${USER}@${d_server} "lsof -nP -iTCP -sTCP:LISTEN | awk '{print $9}' | grep $port" | wc -l)
if [ ${if_port_free} -gt 0 ]; then

	#- check if there is already a matching running notebook
	already_running=$(\ssh -J ${USER}@${t_server} ${USER}@${d_server} "${conda_comm} ${jupyter} list | tail -n +2 | grep :${port} | grep ${USER} | wc -l")

	if [ ${already_running} -gt 0 ]; then
		if [ ${jptstop} == 1 ]; then

			#- ...stop it if wanted...
			printf "\n shutting down open jupyter on ${d_server}, port ${port}"
			\ssh -J ${USER}@${t_server} ${USER}@${d_server} "${conda_comm} ${jupyter} stop ${port}" && exit
		else

			#- ...or reconnect to it
			printf "\n reconnecting to open jupyter on ${d_server}, port ${port}"
			\ssh -o ExitOnForwardFailure=yes -l ${USER} -L ${port}:"${d_server}":${port} -N ${t_server}
			exit
		fi
	else
		echo 'chosen port number ${port} is already in use, exit' && exit
  fi
fi

#- execute remotely the command for jupyter
printf "\n Starting remote jupyter session on ${d_server}"
\ssh -J ${USER}@${t_server} ${USER}@${d_server} "source ~/.bash_private && source ~/.bash_alias && ${remotecomm}" &

#- forwarding the port to your computer for you to access the notebook
printf "\n Forwarding port ${port} to DIAS server ${d_server} "

printf "\n Access jupyter by navigating in your browser to:\n  http://localhost:${port}/ \n\n"
printf "\n Beginning the jupyter log:\n\n"
\ssh -o ExitOnForwardFailure=yes -l ${USER} -L ${port}:"${d_server}":${port} -N ${t_server}

#- Done!

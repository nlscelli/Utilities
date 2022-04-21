#!/usr/bin/env bash
trap "kill 0" SIGINT   #- kill all subshells on exit

#- default inputs
port=8889
d_server='None'
t_server='None'
conda_env='None'
jupyter='jupyter-lab'
USER='None'


#- help function
HELP () {
cat << EOM
##############################################################
Program:   $0, Nicolas Celli 2022
Purpose:   Run jupyterlab/jupyter notebooks on remote machines
Syntax:
           -u Username for access to server
           -s Destination server where to run the jupyter notebook
           -t Tunnelling server needed as intermediate step to
              reach the destination server
           -p port on which to open jupyter (default 8889)
           -e anaconda environment from which to open jupyter (if any)
					 -j what notebook to run: either "jupyter-lab" or "jupyter notebook"
              (within quotes)

Example:
           $0 -u me -s my.server.com -t my.tunnel.server -p 8889 -e my_conda

##############################################################

EOM
}

#- read in options
while getopts hs:t:p:e:j: OPT; do
  case ${OPT} in
    h)  HELP; exit;;
    u)  USER=`echo ${OPTARG}`;;
    s)  d_server=`echo ${OPTARG}`;;
    t)  t_server=`echo ${OPTARG}`;;
    p)  port=`echo ${OPTARG}`;;
    e)  conda_env=`echo ${OPTARG}`;;
    j)  jupyter=`echo ${OPTARG}`;;
    \?) echo "No correct option given; see help:"; HELP; exit;;
  esac
done

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

#- execute remotely the command for jupyter
echo "Starting remote jupyter session on ${d_server}"
\ssh -J ${USER}@${t_server} ${USER}@${d_server} "source ~/.bash_private && source ~/.bash_alias && ${remotecomm}" &

#- forwarding the port to your computer for you to access the notebook
echo "Forwarding port ${port} to DIAS server ${d_server} "

printf "\n Access notebook by navigating in your browser to:\n  http://localhost:${port}/ \n\n"
\ssh -l ${USER} -L ${port}:"${d_server}":${port} -N ${t_server} || echo "Connection aborted"

#- Done!

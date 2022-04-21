#!/usr/bin/env bash

#- defaults
d_server='tinney.cp.dias.ie'
t_server='ariadne.dias.ie'
rdir='NoNe'
USER=${DIASUSER}


HELP () {
cat << EOM
##############################################################
Program:   $0, Nicolas Celli 2021
Purpose:   Easily send commands to be executed on remote servers
           double tunnelling.
Syntax:	   
           -u Username for access to both servers 
           -s Destination server of where the computation must
              be performed
           -t Tunnelling server needed as intermediate step to
              reach the destination server
           -d Remote directory to access before running the command
           -c Command to run on the remote server; multiple commands
              can be appended in shell style (eg "cmd1 && cmd2 && ...")

Example:   
           $0 -u me -s my.server.com -t my.tunnel.server -d /my/dir/ -c 'my_code.sh'


Possible pitfalls:
					if you cannot use your remote aliases, check the .bashrc
					on your remote server and do:

						#- comment out this original line:
						# [ -z "\$PS1" ] && return
						
						#- change it for this:
						if [ -z "\$PS1" ]; then
						  shopt -s expand_aliases
						fi
##############################################################

EOM
}


#- read in options
while getopts hs:t:c:d: OPT; do
	case ${OPT} in
		h)	HELP; exit;;
		u)	USER=`echo ${OPTARG}`;;
		s)	d_server=`echo ${OPTARG}`;;
		t)	t_server=`echo ${OPTARG}`;;
		c)	rcmd=`echo ${OPTARG}`;;
		d)  rdir=`echo ${OPTARG}`;;
		\?) echo "No correct option given; see help:"; HELP; exit;;
	esac
done

#- set no cd command
if [ ${rdir} != 'NoNe' ]; then
	rdir="cd ${rdir} &&"
else
	rdir=""
fi

#- run the actual command
ssh -J ${USER}@${t_server} ${USER}@${d_server} "source ~/.bash_private && source ~/.bash_alias && ${rdir} ${rcmd}"


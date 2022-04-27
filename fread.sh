#!/usr/bin/env bash
#- Fortran-like read function. Reads each line into the variables put as argument.
#  It can rewind, read, skip or repeat each line
#
#- example: 
#  read one argument in the first line and rewind file, skip the second and read 3 arguments from the third line
#	
#       fread.sh rewind mytxtfile arg1
#       fread.sh skip mytxtfile 
#       fread.sh fread mytxtfile arg2 arg3 arg4
#

#- read input
args=(${@})
mode=${args[0]}
readfile=${args[1]}
vars=${args[*]:2}

#-initiate line number
[ -z "${iline+xxx}" ] && iline=0

#- identify mode
case $mode in
        rewind) iline=1;;
        fread)   ((iline++));;
        skip)   ((iline++)); return;;
        repeat) iline=$iline;;
esac

#- read line and assign values to indicated variables, skipping text after ! or #
if [ $iline -gt `cat $readfile | wc -l` ]; then
        echo ERROR: end of file
elif [ `echo $vars | wc -w` -gt `sed "${iline}q;d" ${readfile} | wc -w` ]; then
        echo ERROR: reading too many variables from line
else
        read $(echo $vars) <<< $(sed "${iline}q;d" ${readfile} | awk -F'[!#]' '{print $1}')
fi


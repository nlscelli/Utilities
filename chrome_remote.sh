#!/bin/bash

USER=$DIASUSER
d_server='ariadne.dias.ie'
port=8080

#- check which OS
#- OSX
if [ "$(uname)" == "Darwin" ]; then
	chrpath="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"

#- Linux
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ] && [ $(uname -r | grep -i "microsoft" | wc -l) == 0 ]; then
    # Do something under GNU/Linux platform
	chrpath="/usr/bin/google-chrome"

#- Microsoft Cygwin
elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
	chrpath="C:\Program Files\ \(x86\)\Google\Chrome\Application\chrome.exe"

#- Microsof wsl
elif [ $(uname -r | grep -i "microsoft" | wc -l) == 1 ]; then
	chrpath="/mnt/c/Program\ Files/Google/Chrome/Application/chrome.exe"
fi


#- Forward the port to the remote server
\ssh -C -4 -D ${port} -N ${USER}@${d_server} &
pid=$!

# set up to kill ssh when this script finishes
function finish {
  kill $pid
}

#- execute chrome
#eval ${chrpath} --user-data-dir="$HOME/proxy-profile" --proxy-server="socks5://localhost:8080"
eval ${chrpath} --proxy-server="socks5://localhost:${port}"

#- cleanup
trap finish EXIT

#!/usr/bin/env bash

#- =======================================================
#- create bookmark to current working folder
#	 to allow to cd to folder, this script has to be a function
#  that has to be sourced in your .bashrc (or private,...)
#  e.g.:
#  $ cat ~/.bashrc
#    mystuff
#    source ~/my/folder/to/bmark.sh
#    morestuff
#
#  Once set up, you can view the options by running:
#  bmark -h
#
#- =======================================================

function bmark() {
	#- =======================================================
	#- set library and default action
	bmarkfile=$(echo $(dirname $(which bmark.sh))/.bookmarks)
	[ ! -f $bmarkfile ] && touch $bmarkfile
	action='open'
	
	#- =======================================================
	#- read options
	local OPTIND OPT h s o r l
	while getopts hsorl OPT; do
		case $OPT in
			s)	action='set';;
			o)	action='open';;
			r)  action='remove';;
			l)	action='list';;
			h)  cat << EOM
program:  $(basename $(which bmark.sh))
author:   nicolas celli 2020
purpose:  create, set and change bookmarks for quick access
          folders. It will always bookmark the current 
          directory.
					
syntax:
          bmark <action> my_bookmark_name

action options:
          -h  -> prints this help
          -s  -> adds/replaces a bookmark to current directory
          -o  -> opens (go to) bookmarked directory [default]
          -r  -> removes current bookmark from library
          -l  -> lists bookmarks currently in the library
 
library location:
$(realpath $bmarkfile)

current bookmarks:
$(cat $bmarkfile)

EOM
			return;;
		esac
	done
	
	#- =======================================================
	#- read args
	shift $((OPTIND - 1))
	bname=${1}
	
	case $action in
		#- =====================================================
		#- save/replace new bookmark
		set)
				#- get working directory
				wd=`realpath . | tr -d '\n'`
			
				#- replace
				if [ $(grep -w $bname $bmarkfile | wc -l) -gt 0 ]; then
					(grep -v -w $bname $bmarkfile; printf "%-10s %-100s\n" $bname $wd) > $(dirname $bmarkfile).bmarktmp
					mv $(dirname $bmarkfile).bmarktmp $bmarkfile
					echo "replacing bookmark $bname:"
					echo "old bookmark: "$(awk -v a=$bname '{if($1==a) print $2}' $bmarkfile)
					echo "new bookmark: "$wd
					
				#- set
				else
					printf "%-10s %-100s\n" $bname $wd >> $bmarkfile
					echo "setting new bookmark $bname: "$wd
				fi;;
		#- =====================================================
		#- go to bookmark
		open)
				#- get bookmark from directory and go
				if [ $(grep -w $bname $bmarkfile | wc -l) -gt 0 ]; then
					targetdir=$(awk -v a=$bname '{if($1==a) print $2}' $bmarkfile)
					cd $targetdir
				else
					echo "Error: no bookmark $bmark found; available bookmarks:"
					cat $bmarkfile
					return
				fi;;
		#- =====================================================
		#- remove bookmark from list
		remove)
				echo "removing bookmark $bname: " $(awk -v a=$bname '{if($1==a) print $2}' $bmarkfile)
				grep -v -w $bname $bmarkfile > $(dirname $bmarkfile).bmarktmp
	      mv $(dirname $bmarkfile).bmarktmp $bmarkfile;;
		#- =====================================================
		#- list bookmarks
		list)
				echo "Existing bookmarks in library:"
				cat $bmarkfile
				echo "";;
	esac
}

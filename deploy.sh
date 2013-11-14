#!/bin/bash
########## Links the scripts in this directory into ~/bin so they show up in the PATH and can be called anywehre.

BIN=$(cd ~/bin; pwd)
HERE=`pwd`;
for f in $(ls *.sh)
do
	if [ $f != "deploy.sh" ]; then
		#delete the existing link if it exists
		[ -a "$BIN/$f" ] && rm -f "$BIN/$f" 
		ln -s "$HERE/$f" "$BIN/$f"
	fi
done
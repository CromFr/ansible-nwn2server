#!/bin/bash

mkdir -p staging
cd staging

if [ -d nwn2server ]; then
	echo "You need to assemble nwn2server files first"
	echo "Run `./assemble-nwn2server.sh /path/to/nwn2/install/folder`"
	exit 1
fi

# wget https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe

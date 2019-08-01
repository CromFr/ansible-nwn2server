#!/bin/bash

if [ "$#" != "1" ]; then
	echo "Usage: $0 nwn2_install_path"
	echo "Copy files from a real nwn2 installation to ./staging/nwn2server to build a minimal server install"
	exit 1
fi


set -e
shopt -s nocaseglob

NWN2="$1"
DEST="$PWD/staging/nwn2server"

mkdir -p "$DEST"
cd "$NWN2"
cp --parents -v \
	Campaigns/Neverwinter\ Nights\ 2\ Campaign*/Campaign.cam \
	\
	Data/2DA*.zip \
	Data/convo*.zip \
	Data/Ini*.zip \
	Data/lod-merged*.zip \
	Data/NWN2_Models*.zip \
	Data/scripts*.zip \
	Data/SpeedTree*.zip \
	Data/Templates*.zip \
	Data/walkmesh*.zip \
	\
	dialog*.tlk \
	\
	granny2.dll \
	mss32.dll \
	NWN2_MemoryMgr.dll \
	NWN2_MemoryMgr_amdxp.dll \
	\
	nwn?.ini \
	nwn?player.ini \
	nwnpatch.ini \
	\
	nwn2server.exe \
	\
	"$DEST"


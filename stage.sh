#!/bin/bash

set -e

STAGING=$PWD/staging


if [ ! -d "$STAGING/nwnx_plugins" ]; then
	echo "You can customize your nwnx install by adding plugins inside $STAGING/nwnx_plugins (you need to create it)"
	echo "Plugins/configs handled by ansible: nwnx xp_mysql"
	echo "If you do not want any additional plugins, create an empty directory to continue"
	exit 1
fi

[ -d "$STAGING/nwn-lib-d/" ] || git clone https://github.com/CromFr/nwn-lib-d.git $STAGING/nwn-lib-d/
cd $STAGING/nwn-lib-d/
dub add-local $STAGING/nwn-lib-d/

dub build -b release :nwn-gff
dub build -b release :nwn-erf

[ -d "$STAGING/LcdaTools/" ] || git clone https://github.com/CromFr/LcdaTools.git $STAGING/LcdaTools/
cd $STAGING/LcdaTools/

cd $STAGING/LcdaTools/ItemUpdater
dub build -b release

cd $STAGING/LcdaTools/ModuleInstaller
dub build -b release

cd $STAGING/LcdaTools/StagingTool
dub build -b release


[ -d "$STAGING/LcdaAccountManager/" ] || git clone https://github.com/CromFr/LcdaAccountManager.git $STAGING/LcdaAccountManager/
cd $STAGING/LcdaAccountManager/

# # LcdaAccountManager
# git checkout origin/new_api
# dub build -b release

# # LcdaApi
# git checkout master
# dub build -b release
# npm install
# npm run build:prod

#!/bin/sh
set -eu
cd "$(dirname $(readlink -f "$0"))" || exit 1

####################################################################################################
###                                        Source                                                ###
####################################################################################################

. ../utils/gMsg.sh
. ../repo/utils/gConfig.sh

####################################################################################################
###                                       Utils                                                  ###
####################################################################################################

function _deployWelcome() {
	_msgInfo "Deploying Welcome"

	_msg "Uploading"
	sshpass -p "$gRepoPasswd" rsync -aru --delete --human-readable --progress goylin-web "${repoUser}"@"${repoSrv}":"${repoRemotePath}"

	return 0
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################


[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit 1

clear; _msgOk "-- gDeploySrv --"

_deployWelcome

_msgOk "\,,/_(o.O)_\,,/"
_msg "SRV Deployed"
echo; exit 0
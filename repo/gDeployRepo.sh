#!/bin/sh
set -eu
cd "$(dirname $(readlink -f "$0"))" || exit 1

####################################################################################################
###                                        Source                                                ###
####################################################################################################

. ../utils/gMsg.sh
. utils/gConfig.sh

####################################################################################################
###                                        Help                                                  ###
####################################################################################################

function _help() {
	_msgAlert "Flags:"
	_msg "-a: Deploy AUR/pkg-a"
	_msg "-g: Deploy Goylin/pkg-g"
	_msg "-d: Deploy Default"
	_msg "-f: Full Deploy"

	_msgAlert "Usage:"
	_msg "gDeployRepo -opt"

	echo; exit 0
}

####################################################################################################
###                                        Opt                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit 1

deployAur=0
deployGoylin=0
deployDefault=0

while getopts "agdf" opt; do
	case $opt in
		a) deployAur=1 ;;
		g) deployGoylin=1 ;;
		d) deployDefault=1 ;;
		f)
			deployAur=1
			deployGoylin=1
			deployDefault=1
		;;
		*) _help ;;
	esac
done

####################################################################################################
###                                       Utils                                                  ###
####################################################################################################

function _deployRepo() {
	_msgInfo "Deploying ${repoToDeploy}"

	# _msg "Clean repo DB"
	# [ -f "${repoToDeploy}/${repoToDeploy}.db.tar.gz" ] && rm -fv "${repoToDeploy}/${repoToDeploy}.db.tar.gz"
	# repo-add "${repoToDeploy}/${repoToDeploy}"

	# _msg "Add all packages to DB"
	# [[ "$(ls $repoToDeploy | grep "pkg.tar.zst")" ]] && repo-add -nqR ${repoToDeploy}/${repoToDeploy}.db.tar.gz ${repoToDeploy}/*.pkg.tar.zst
	# [[ "$(ls $repoToDeploy | grep "pkg.tar.xz")" ]] && repo-add -nqR ${repoToDeploy}/${repoToDeploy}.db.tar.gz ${repoToDeploy}/*.pkg.tar.xz

	_msg "Uploading"
	sshpass -p "$gRepoPasswd" rsync -aru --delete --human-readable --progress "/srv/http/${repoToDeploy}" "${repoUser}"@"${repoSrv}":"${repoRemotePath}"

	return 0
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

clear; _msgOk "-- gDeployRepo --"

[ $deployGoylin -eq 1 ] && repoToDeploy="$gRepoName" && _deployRepo
[ $deployAur -eq 1 ] && repoToDeploy="$aurRepoName" && _deployRepo
[ $deployDefault -eq 1 ] && repoToDeploy="$repoName" && _deployRepo

_msgOk "\,,/_(o.O)_\,,/"
_msg "Repo Deployed"
echo; exit 0
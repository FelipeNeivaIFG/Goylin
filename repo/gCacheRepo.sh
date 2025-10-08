#!/bin/bash

set -ue # Unbound Variables || Error == exit

cd "$(dirname $(readlink -f "$0"))" || exit 1

####################################################################################################
###                                        Source                                                ###
####################################################################################################

. ../installer/utils/msg.sh
. utils/repoConf.sh

####################################################################################################
###                                        Help                                                  ###
####################################################################################################

function _help() {
	_msgAlert "Flags:"
	_msg "-n : Start Clean Repo"
	_msg "-d : Deploy"
	_msg "-p : Single Package"

	echo; exit 0
}

####################################################################################################
###                                        Opts                                                  ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

cacheNewRepo=0
cachedRepoDeploy=0
singlePkg=0
pkgName=""

while getopts "ndp" opt; do
	case $opt in
		n) cacheNewRepo=1 ;;
		d) cachedRepoDeploy=1 ;;
		p) singlePkg=1; pkgName=$2 ;;
		*) _help ;;
	esac
done

####################################################################################################
###                                        Utils                                                 ###
####################################################################################################

function _prepare() {
	_msgInfo "Preparing"

	[ -d ".blankdb" ] && rm -rf .blankdb
	mkdir -p .blankdb
}

function _blankRepo() {
	_msg "Blank Repo"

	rm -fr "${repoLocalPath}${repoName}"
	mkdir -p "${repoLocalPath}${repoName}"
	touch "${repoLocalPath}${repoName}/${repoName}.db.tar.gz"
	touch "${repoLocalPath}${repoName}/${repoName}.db"

	_msg "Getting better mirrors"
	reflector --latest 5 --country BR --sort rate --save /etc/pacman.d/mirrorlist
}

function _cacheRepo() {
	_msgInfo "Caching PKGs from utils/pkgList.txt"

	pacman -Syyw --disable-download-timeout --config utils/pacman_update.conf --noconfirm --cachedir "${repoLocalPath}${repoName}" --dbpath .blankdb - < utils/pkgList.txt

	_msgInfo "Adding PKGs to Repo"

	[[ "$(ls "${repoLocalPath}${repoName}" | grep "pkg.tar.zst")" ]] && repo-add -nR "${repoLocalPath}${repoName}/${repoName}.db.tar.gz" ${repoLocalPath}"${repoName}"/*.pkg.tar.zst
	[[ "$(ls "${repoLocalPath}${repoName}" | grep "pkg.tar.xz")" ]] && repo-add -nR "${repoLocalPath}${repoName}/${repoName}.db.tar.gz" ${repoLocalPath}"${repoName}"/*.pkg.tar.xz

	return 0
}

function _cachePkg() {
	_msgInfo "Caching $1"

	pacman -Syyw --disable-download-timeout --config utils/pacman_update.conf --noconfirm --cachedir "${repoLocalPath}${repoName}" --dbpath .blankdb $1
	
	_msgInfo "Adding PKGs to Repo"
	[[ "$(ls "${repoLocalPath}$repoName" | grep "pkg.tar.zst")" ]] && repo-add -nR "${repoLocalPath}${repoName}/${repoName}.db.tar.gz" ${repoLocalPath}"$repoName"/*.pkg.tar.zst
	[[ "$(ls "${repoLocalPath}$repoName" | grep "pkg.tar.xz")" ]] && repo-add -nR "${repoLocalPath}${repoName}/${repoName}.db.tar.gz" ${repoLocalPath}"$repoName"/*.pkg.tar.xz

	return 0
}

function _deployCached() {
	_msgInfo "Deploying to server"

	sshpass -p "${gRepoPasswd}" rsync -aru --delete --human-readable --progress "${repoLocalPath}${repoName}" "${repoUser}"@"${repoSrv}":"${repoRemotePath}"
}

function _finishUp() {
	_msgInfo "Finishing"

	_msg "Clean up .blankdb"
	rm -fr .blankdb
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

clear; _msgOk "-- Repository Cached --"

_prepare
[ $cacheNewRepo -eq 1 ] && _blankRepo
[ $singlePkg -eq 0 ] && _cacheRepo || _cachePkg $pkgName
[ $cachedRepoDeploy -eq 1 ] && _deployCached
_finishUp

echo; exit 0
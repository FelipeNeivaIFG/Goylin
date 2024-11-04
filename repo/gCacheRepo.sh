#!/bin/bash
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
	_msg "-n : Start Clean Repo"
	_msg "-d : Deploy"

	echo; exit 0
}

####################################################################################################
###                                        Opts                                                  ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

cacheNewRepo=0
cachedRepoDeploy=0

while getopts "nd" opt; do
    case $opt in
        n) cacheNewRepo=1 ;;
		d) cachedRepoDeploy=1 ;;
        *) _help ;;
    esac
done

####################################################################################################
###                                        Utils                                                 ###
####################################################################################################

function _prepare() {
	_msgInfo "Preparing"
	[ -d "blankdb" ] && rm -rf blankdb
	mkdir -pv blankdb

	return 0
}

function _blankRepo() {
	_msg "Blank Repo"
	rm -fr "/srv/http/${repoName}"
	mkdir -pv "/srv/http/${repoName}"
	touch "/srv/http/${repoName}/${repoName}.db.tar.gz"
	touch "/srv/http/${repoName}/${repoName}.db"

	_msg "Getting better mirrors"
	reflector --latest 5 --country BR --sort rate --save /etc/pacman.d/mirrorlist

	return 0
}

function _cacheRepo() {
	_msgInfo "Caching PKGs from utils/pkgList.txt"
	pacman -Syyw --disable-download-timeout --config ../utils/pacman_update.conf --noconfirm --cachedir "/srv/http/${repoName}" --dbpath blankdb - < utils/gPkgList.txt
	
	_msgInfo "Adding PKGs to Repo"
	[[ "$(ls "/srv/http/$repoName" | grep "pkg.tar.zst")" ]] && repo-add -nR "/srv/http/${repoName}/${repoName}.db.tar.gz" /srv/http/"$repoName"/*.pkg.tar.zst
	[[ "$(ls "/srv/http/$repoName" | grep "pkg.tar.xz")" ]] && repo-add -nR "/srv/http/${repoName}/${repoName}.db.tar.gz" /srv/http/"$repoName"/*.pkg.tar.xz

	return 0
}

function _deployCached() {
	_msgInfo "Deploying to server"
	sshpass -p "$gRepoPasswd" rsync -aru --delete --human-readable --progress "/srv/http/${repoName}" "${repoUser}"@"${repoSrv}":"${repoRemotePath}"

	return 0
}

function _finishUp() {
	_msgInfo "Finishing"

	_msg "Clean up blankdb"
	rm -fr blankdb

	return 0
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

clear; _msgOk "-- gCacheRepo --"

_prepare
[ $cacheNewRepo -eq 1 ] && _blankRepo
_cacheRepo
[ $cachedRepoDeploy -eq 1 ] && _deployCached
_finishUp

_msgOk "\,,/_(o.O)_\,,/"
_msg "PKGs cached!"
echo; exit 0
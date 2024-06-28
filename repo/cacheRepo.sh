#!/bin/bash
set -u # Unbound Variables == exit
set -e # Error == exit
set -o pipefail # Error on pipe end == exit

####################################################################################################
###                                        Source                                                ###
####################################################################################################

source utils/gMsg.sh

repoName="goylin-repo"
repoUser="suporte"
repoSrv="10.11.0.111"
repoRemotePath="/var/www/html/"

####################################################################################################
###                                        Help                                                  ###
####################################################################################################

function _help() {
	_msgInfo "Cache Repo flags:"

	_msgOpt "-n : Start Clean Repo"

	echo; exit 0
}

####################################################################################################
###                                        Flags                                                 ###
####################################################################################################

newRepo=0

while getopts "n" opt; do
    case $opt in
        n) newRepo=1 ;;
        *) _help ;;
    esac
done

####################################################################################################
###                                       UTILS                                                  ###
####################################################################################################

function _repoBlankDb() {
	_msg "Clean blankdb"

	[ -d "blankdb" ] && rm -rf blankdb
	mkdir blankdb
}

function _repoBetterMirrors() {
	_msg "Getting better mirrors"

	reflector --latest 5 --country BR --sort rate --save /etc/pacman.d/mirrorlist 1> /dev/null
}

function _CleanUpLocalRepo () {
	_msg "Cleaning Local Repo"

	rm $repoName/*
	touch ${repoName}/${repoName}.db.tar.gz
}

_repoSyncDown() {
	_msg "Syncing server repository to local"

	wget -r -np -nH --cut-dirs=1 -N -P $repoName http://${repoSrv}/${repoName}
}

function _repoCacheList() {
	_msgInfo "Caching PKGs from pkg-list.txt"

	pacman -Syyw --disable-download-timeout --config utils/pacman_update.conf --noconfirm --cachedir $repoName --dbpath blankdb - < pkg-list.txt
}

function _repoAddPKGs() {
	_msg "Adding PKGs to Repo"

	[[ "$(ls $repoName | grep "pkg.tar.zst")" ]] && repo-add -n ${repoName}/${repoName}.db.tar.gz ${repoName}/*.pkg.tar.zst
	[[ "$(ls $repoName | grep "pkg.tar.xz")" ]] && repo-add -n ${repoName}/${repoName}.db.tar.gz ${repoName}/*.pkg.tar.xz

	return 0
}

function _repoSyncUp() {
	_msgInfo "Syncing local repository to server"

	rsync -aru --delete --human-readable --progress "${repoName}" "${repoUser}"@"${repoSrv}":"${repoRemotePath}"
}

function _repoCleanUp() {
	_msg "Clean up blankdb"
	rm -r blankdb
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

clear
[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

_msgInfo "Caching..."

_repoBlankDb
_repoBetterMirrors

if [ $newRepo -eq 1 ]; then
    _CleanUpLocalRepo
else
    _repoSyncDown
fi

_repoCacheList
_repoAddPKGs
_repoSyncUp
_repoCleanUp

_msg "Updating Pacman"
pacman -Syy 1> /dev/null

_msgOk "PKGs cached!"
_msgOk "\,,/_(o.O)_\,,/"

exit 0
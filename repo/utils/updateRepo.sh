#!/bin/bash

repoName="goylin-repo"
repoUser="suporte"
repoSrv="10.11.0.111"
repoRemotePath="/var/www/html/"
CARCH=""

function _repoBlankDb() {
	_msg "Clean blankdb"

	[ -d "blankdb" ] && rm -rf blankdb
	mkdir -p blankdb
}

function _repoBetterMirrors() {
	_msg "Getting better mirrors"
	_msgAlert "FIX THIS!"
	# reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist 1> /dev/null
}

_repoSyncDown() {
	_msg "Syncing server repository to local"
	rsync -aru ${repoUser}@${repoSrv}:${repoRemotePath}/${repoName} . --progress --human-readable
}

function _repoCacheList() {
	_msgInfo "Caching PKGs from pkg-list.txt"
	pacman -Syyw --config utils/pacman_update.conf --noconfirm --cachedir $repoName --dbpath blankdb - < pkg-list.txt
}

function _repoCachePKG() {
	_msgInfo "Caching PKGs from pkg-list.txt"
	pacman -Syyw --config utils/pacman_update.conf --noconfirm --cachedir $repoName --dbpath blankdb $1
}

function _repoAddPKGs() {
	_msg "Adding PKG to Repo"
	[ ! -f ${repoName}/${repoName}.db.tar.gz ] && touch ${repoName}/${repoName}.db.tar.gz

	[[ "$(ls $repoName | grep "pkg.tar.zst")" ]] && repo-add -n ${repoName}/${repoName}.db.tar.gz ${repoName}/*.pkg.tar.zst
	[[ "$(ls $repoName | grep "pkg.tar.xz")" ]] && repo-add -n ${repoName}/${repoName}.db.tar.gz ${repoName}/*.pkg.tar.xz
}

function _repoAddSingle() {
	_msg "Adding $1 to Repo"
	[ ! -f ${repoName}/${repoName}.db.tar.gz ] && touch ${repoName}/${repoName}.db.tar.gz

	repo-add ${repoName}/${repoName}.db.tar.gz ${repoName}/${1}*.pkg.tar.zst
}

function _repoSyncUp() {
	_msgInfo "Syncing local repository to server"
	rsync -aru --delete --human-readable --progress "${repoName}" "${repoUser}"@"${repoSrv}":"${repoRemotePath}"
}

_repoCleanUp() {
	_msg "Clean up blankdb"
	rm -r blankdb
}
#!/bin/bash

repoName="goylin-repo"
repoUser="suporte"
repoSrv="10.11.0.111"
repoRemotePath="/var/www/html/"
CARCH=""

function _repoBlankDb() {
	_msg "Clean blankdb"

	[ -d "blankdb" ] && rm -rf blankdb
	mkdir blankdb
}

function _repoBetterMirrors() {
	_msg "Getting better mirrors"

	reflector --latest 5 --country BR --sort rate --save /etc/pacman.d/mirrorlist 1> /dev/null
}

_CleanUpLocalRepo () {
	_msg "Cleaning Local Repo"

	rm $repoName/*
	touch ${repoName}/${repoName}.db.tar.gz
}

_repoSyncDownGoylin() {
	_msg "Downloading goylin PKGs from remote repo"

	wget -qr -np -nH --cut-dirs=1 -N --accept 'g-*,gapp-*,gp-*,gc-*' -P $repoName http://${repoSrv}/${repoName}
}

_repoSyncDown() {
	_msg "Syncing server repository to local"

	wget -qr -np -nH --cut-dirs=1 -N --accept 'goylin*, *.pkg.*' -P $repoName http://${repoSrv}/${repoName}
}

function _repoCacheList() {
	_msgInfo "Caching PKGs from pkg-list.txt"

	pacman -Syyw --config utils/pacman_update.conf --noconfirm --cachedir $repoName --dbpath blankdb - < pkg-list.txt
}

function _repoCachePKG() {
	_msgInfo "Caching PKG"

	pacman -Syyw --config utils/pacman_update.conf --noconfirm --cachedir $repoName --dbpath blankdb $1
}

function _repoAddPKGs() {
	_msg "Adding PKGs to Repo"

	[[ "$(ls $repoName | grep "pkg.tar.zst")" ]] && repo-add -n ${repoName}/${repoName}.db.tar.gz ${repoName}/*.pkg.tar.zst
	[[ "$(ls $repoName | grep "pkg.tar.xz")" ]] && repo-add -n ${repoName}/${repoName}.db.tar.gz ${repoName}/*.pkg.tar.xz

	return 0
}

function _repoAddSingle() {
	_msg "Adding $1 to Repo"

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
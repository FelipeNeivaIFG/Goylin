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
	_msg "-a: Build AUR/pkg-a"
	_msg "-u: Update AUR/pkg-a"
	_msg "-g: Build Goylin/pkg-g"
	_msg "-d: Deploy"

	_msgAlert "Usage:"
	_msg "gBuildPkg -opt pkgName"

	echo; exit 0
}

####################################################################################################
###                                        Opt                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit 1

aurUpdate=0
pkgDeploy=0
pkgType=""

while getopts "agud" opt; do
	case $opt in
		a) pkgType="pkg-a" ;;
		g) pkgType="pkg-g" ;;
		u) aurUpdate=1 ;;
		d) pkgDeploy=1 ;;
		*) _help ;;
	esac
done

[ -z "$pkgType" ] || [ $# -lt 2 ] && _help

pkgName="$2"

####################################################################################################
###                                       Build                                                  ###
####################################################################################################

function _preBuild() {
	cd "$pkgName"

	if [ -f "build.sh" ] && [ "$pkgType" == "pkg-g" ]; then
		_msgInfo "Running build.sh"
		. ./build.sh
	fi
}

function _bootstrapChroot() {
	_msgInfo "Bootstraping chroot"
	chroot="/pkgRoot"

	_msg "Ensure clean work directory"
	[ -d "$chroot" ] && rm -rf "$chroot"
	mkdir -p "$chroot"

	_msg "Building chroot"
	mkarchroot -C "../../../${pacmanConf}" "${chroot}/root" base-devel git 1> /dev/null
	cp -f "../../../${pacmanConf}" "${chroot}/root/etc/pacman.conf"
	arch-nspawn -C "../../../${pacmanConf}" "${chroot}/root" pacman -Syu 1> /dev/null

	return 0
}

function _buildPKG() {
	_msgInfo "Build"

	_msg "Building $pkgName"
	makechrootpkg -c -r "$chroot" #1> /dev/null

	_msg "Clean up build files"
	rm -rf "$chroot"

	return 0
}

function _syncDownRepoDb() {
	_msgInfo "Sync down DB for deploy"
	wget -r -np -nH --cut-dirs=1 -N -P "/srv/http/$pkgRepo" "http://${repoSrv}/${pkgRepo}/${pkgRepo}.db.tar.gz"
}

function _addToRepo() {
	_msgInfo "Adding ${pkgName} to ${pkgRepo}"
	cd ../../

	_msg "Removing Old Version"
	find "/srv/http/${pkgRepo}" -maxdepth 1 -name "${pkgName}-*" -exec rm -v {} +

	_msg "Adding $pkgName to Repo"
	mv -f "${pkgType}/${pkgName}/${pkgName}"*.pkg.tar.zst "/srv/http/${pkgRepo}"
	repo-add "/srv/http/${pkgRepo}/${pkgRepo}.db.tar.gz" "/srv/http/${pkgRepo}/${pkgName}"*.pkg.tar.zst
}

function _deployToRepo () {
	_msgInfo "Deploy updated ${pkgRepo}"

	_msg "Sync up"
	sshpass -p "$gRepoPasswd" rsync -au --human-readable --progress /srv/http/${pkgRepo}/${pkgName}*.pkg.tar.zst ${repoUser}@${repoSrv}:${repoRemotePath}/${pkgRepo}
	sshpass -p "$gRepoPasswd" rsync -au --human-readable --progress /srv/http/${pkgRepo}/${pkgRepo}.db.tar.gz ${repoUser}@${repoSrv}:${repoRemotePath}/${pkgRepo}

	_msg "Updating Pacman"
	pacman --config ../utils/pacman_local.conf -Sy
	echo; pacman --config ../utils/pacman_local.conf -Ss "$pkgName"
}

####################################################################################################
###                                       AUR                                                    ###
####################################################################################################

function _aurGitClone() {
	if [ -f "${pkgName}/gLocked" ] && [ "$pkgType" == "pkg-a" ]; then
		_msgAlert "Build has gLocked file"
		exit 0
	fi

	_msgInfo "Downloading $pkgName"
	git clone "https://aur.archlinux.org/${pkgName}.git" 1> /dev/null
	chmod a+rwx -R "$pkgName"

	if [ ! -f "${pkgName}/PKGBUILD" ]; then
		_msgAlert "$pkgName not found!"
		rm -r "$pkgName"
		exit 1
	fi

	return 0
}

function _aurVerCheck() {
	_msgInfo "Comparing local and AUR version"
	localPkgVersion=$(grep "^pkgver=" "${pkgName}/PKGBUILD" | cut -d= -f2)
	localPkgVersion="${localPkgVersion}:$(grep "^pkgrel=" "${pkgName}/PKGBUILD" | cut -d= -f2)"
	localPkgVersion="${localPkgVersion}:$(grep "^epoch=" "${pkgName}/PKGBUILD" | cut -d= -f2)"

	aurPkgVersionInfo=$(curl -s "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${pkgName}")
	aurPkgVersion=$(echo "$aurPkgVersionInfo" | grep "^pkgver=" | cut -d= -f2)
	aurPkgVersion="${aurPkgVersion}:$(echo "$aurPkgVersionInfo" | grep "^pkgrel=" | cut -d= -f2)"
	aurPkgVersion="${aurPkgVersion}:$(echo "$aurPkgVersionInfo" | grep "^epoch=" | cut -d= -f2)"

	_msg "Local: ${localPkgVersion}"
	_msg "AUR:   ${aurPkgVersion}"

	if [ "$localPkgVersion" != "$aurPkgVersion" ]; then
		_msgInfo "${pkgName} has updates."
		_msg "Removing old version"
		rm -r "$pkgName"
		_aurGitClone
	else
		_msgOk "${pkgName} is updated."
		exit 0
	fi

	return 0
}

####################################################################################################
###                                       Utils                                                  ###
####################################################################################################

function _prepare() {
	_msgInfo "Repo Sync"
	[ ! -d "/srv/http/goylin-repo-aur" ] && mkdir "/srv/http/goylin-repo-aur"
	[ ! -f "/srv/http/goylin-repo-aur/goylin-repo-aur.db.tar.gz" ] && touch "/srv/http/goylin-repo-aur/goylin-repo-aur.db.tar.gz"
	[ ! -d "/srv/http/goylin-repo-g" ] && mkdir "/srv/http/goylin-repo-g"
	[ ! -f "/srv/http/goylin-repo-g/goylin-repo-g.db.tar.gz" ] && touch "/srv/http/goylin-repo-g/goylin-repo-g.db.tar.gz"

	[ $pkgDeploy -eq 0 ] && pacmanConf="utils/pacman_dev.conf" || pacmanConf="utils/pacman_local.conf"
	pacman -Syy --config "../${pacmanConf}" 1> /dev/null

	_msgInfo "Preparing"
	case "$pkgType" in
		pkg-a)
			pkgRepo="$aurRepoName"
			[ ! -d "$pkgType" ] && mkdir "${pkgType}"
			cd "$pkgType"

			[ ! -d "$pkgName" ] && _aurGitClone
			[ $aurUpdate -eq 1 ] && _aurVerCheck
			;;

		pkg-g) 
			pkgRepo="$gRepoName"
			[ ! -d "$pkgType" ] && mkdir "$pkgType"
			cd "$pkgType"
			;;
	esac

	return 0
}

####################################################################################################
###                                       Init                                                   ###
####################################################################################################

clear; _msgOk "-- gBuildPkg --"

_prepare
_preBuild
_bootstrapChroot
_buildPKG
[ $pkgDeploy -eq 1 ] && _syncDownRepoDb
_addToRepo
[ $pkgDeploy -eq 1 ] && _deployToRepo

_msgOk "Finished ${pkgName} ^_^"
echo; exit 0
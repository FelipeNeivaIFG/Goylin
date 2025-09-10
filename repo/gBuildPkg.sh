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

	_msg "-a: Build AUR/pkg-a"
	_msg "-au: Update AUR/pkg-a"
	_msg "-c: Build Custom/pkg-c"
	_msg "-g: Build Goylin/pkg-g"
	_msg "-d: Deploy"

	echo; exit 0
}

####################################################################################################
###                                        Opt                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit 1

aurUpdate=0
pkgDeploy=0
pkgType=""

while getopts "agcud" opt; do
	case $opt in
		a) pkgType="pkg-a" ;;
		g) pkgType="pkg-g" ;;
		c) pkgType="pkg-c" ;;
		u) aurUpdate=1 ;;
		d) pkgDeploy=1 ;;
		*) _help ;;
	esac
done

[ -z "${pkgType}" ] || [ $# -lt 2 ] && _help

pkgName="$2"

####################################################################################################
###                                       Build                                                  ###
####################################################################################################

function _prepare() {
	_msgInfo "Preparing"

	[ ! -d "/srv/http/${aRepoName}" ] && mkdir "/srv/http/${aRepoName}"
	[ ! -f "/srv/http/${aRepoName}/${aRepoName}.db.tar.gz" ] && touch "/srv/http/${aRepoName}/${aRepoName}.db.tar.gz"
	[ ! -d "/srv/http/${gRepoName}" ] && mkdir "/srv/http/${gRepoName}"
	[ ! -f "/srv/http/${gRepoName}/${gRepoName}.db.tar.gz" ] && touch "/srv/http/${gRepoName}/${gRepoName}.db.tar.gz"
	[ ! -d "/srv/http/${cRepoName}" ] && mkdir "/srv/http/$cRepoName"
	[ ! -f "/srv/http/${cRepoName}/${cRepoName}.db.tar.gz" ] && touch "/srv/http/${cRepoName}/${cRepoName}.db.tar.gz"

	[ ${pkgDeploy} -eq 0 ] && pacmanConf="../utils/pacman_dev.conf" || pacmanConf="../installer/utils/pacman_goylin.conf"

	pacman -Syy --config "${pacmanConf}" 1> /dev/null

	case "${pkgType}" in
		pkg-g)
			pkgRepo="${gRepoName}"
			cd "${pkgType}"
			[ ! -d "${pkgName}" ] && _msgAlert "${pkgName} not found!" && exit 1
			;;

		pkg-c)
			pkgRepo="${cRepoName}"
			[ ! -d "${pkgName}" ] && _msgAlert "${pkgName} not found!" && exit 1
			cd "$pkgType"
			;;

		pkg-a)
			pkgRepo="${aRepoName}";
			cd "${pkgType}"

			if [[ ${aurUpdate} -eq 1  && -d "${pkgName}" ]]; then
				[ -f "${pkgName}/gLocked" ] && _msgAlert "AUR pkg has gLocked file" && exit 0
				_aurVerCheck
			fi

			[ ! -d "${pkgName}" ] && _aurGitClone
			;;
	esac

	cd "$pkgName"
}

function _preBuild() {
	if [ -f "gBuild.sh" ] && [ "$pkgType" != "pkg-a" ]; then
		_msgInfo "Running gBuild.sh"

		. ./gBuild.sh
	fi
}

function _bootstrapChroot() {
	_msgInfo "Bootstraping chroot"

	chroot="/tmp/pkgRoot"

	_msg "Ensure clean work directory"

	[ -d "${chroot}" ] && rm -rf "${chroot}"
	mkdir -p "${chroot}"

	_msg "Building chroot"

	mkarchroot -C "../../${pacmanConf}" "${chroot}/root" base-devel git 1> /dev/null
	cp -f "../../${pacmanConf}" "${chroot}/root/etc/pacman.conf"
	arch-nspawn -C "../../${pacmanConf}" "${chroot}/root" pacman -Syu 1> /dev/null
}

function _buildPKG() {
	_msgInfo "Build"

	_msg "Building ${pkgName}"

	makechrootpkg -c -r "${chroot}" #1> /dev/null

	_msg "Clean up build files"

	rm -rf "${chroot}"
}

####################################################################################################
###                                       AUR                                                    ###
####################################################################################################

function _aurGitClone() {
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
	aurPkgVersion=$(echo "${aurPkgVersionInfo}" | grep "^pkgver=" | cut -d= -f2)
	aurPkgVersion="${aurPkgVersion}:$(echo "$aurPkgVersionInfo" | grep "^pkgrel=" | cut -d= -f2)"
	aurPkgVersion="${aurPkgVersion}:$(echo "$aurPkgVersionInfo" | grep "^epoch=" | cut -d= -f2)"

	_msg "Local: ${localPkgVersion}"
	_msg "AUR:   ${aurPkgVersion}"

	if [ "${localPkgVersion}" != "${aurPkgVersion}" ]; then
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
###                                       Repo                                                   ###
####################################################################################################

function _syncDownRepoDb() {
	_msgInfo "Sync down DB for deploy"

	wget -r -np -nH --cut-dirs=1 -N -P "${repoLocalPath}${pkgRepo}" "http://${repoSrv}/${pkgRepo}/${pkgRepo}.db.tar.gz"
}

function _addToRepo() {
	_msgInfo "Adding ${pkgName} to ${pkgRepo}"

	cd ../../

	_msg "Adding $pkgName to Repo"

	mv -f "${pkgType}/${pkgName}/${pkgName}"*.pkg.tar* "/${repoLocalPath}${pkgRepo}"
	repo-add -R "${repoLocalPath}${pkgRepo}/${pkgRepo}.db.tar.gz" "${repoLocalPath}${pkgRepo}/${pkgName}"*.pkg.tar*
}

function _deployToRepo () {
	_msgInfo "Deploy updated ${pkgRepo}"

	_msg "Sync up"

	sshpass -p "${gRepoPasswd}" rsync -au --human-readable --progress ${repoLocalPath}${pkgRepo}/${pkgName}*.pkg.tar.zst ${repoUser}@${repoSrv}:${repoRemotePath}/${pkgRepo}
	sshpass -p "${gRepoPasswd}" rsync -au --human-readable --progress ${repoLocalPath}${pkgRepo}/${pkgRepo}.db.tar.gz ${repoUser}@${repoSrv}:${repoRemotePath}/${pkgRepo}

	_msg "Updating Pacman"

	pacman --config "${pacmanConf}" -Sy
	pacman --config "${pacmanConf}" -Ss "${pkgName}"
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
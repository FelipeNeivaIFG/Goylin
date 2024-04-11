#!/bin/bash

set -u # Unbound Variables == exit
set -e # Error == exit
set -o pipefail # Error on pipe end == exit

####################################################################################################
###                                        Source                                                ###
####################################################################################################

source utils/gMsg.sh
source utils/updateRepo.sh

####################################################################################################
###                                        HELP                                                  ###
####################################################################################################

function _help() {
	echo
	_msgAlert "Flags:"
	_msg "-a: AUR PKGs"
	_msg "-g: Goylin PKGs"
	echo
	exit 2
}

####################################################################################################
###                                        OPT                                                   ###
####################################################################################################

pkgType=""
forceUpdate=0

while getopts "agf" opt; do
	case $opt in
		a) pkgType="pkg-a" ;;
		g) pkgType="pkg-g" ;;
		f) forceUpdate=1 ;;
		\?) _help ;;
	esac
done

[ "${pkgType}" == "" ] && _help

####################################################################################################
###                                       AUR                                                    ###
####################################################################################################

function _checkVersion() {
	_msgInfo "Comparing local and AUR version"
	localVersion=""
	if [ "$forceUpdate" -eq 0 ]; then
		if [ -f ${pkgName}/PKGBUILD ]; then
			source ./${pkgName}/PKGBUILD
			localVersion="${pkgver}-${pkgrel}"

			aurInfo=$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg=$pkgName")
			aurVersion=$(echo "$aurInfo" | grep -oP '"Version":"\K[^"]+')

			_msg "Local: ${localVersion}"
			_msg "AUR: ${aurVersion}"
		fi

		if [[ -n "$localVersion" && "$localVersion" == "$aurVersion" ]]; then
			_msgOk "${pkgName} is updated." && exit 1
		fi
	else
		_msgAlert "Forced update"
		[ -d $pkgName ] && rm -rf $pkgName
	fi
}

function _gitpkg() {
	_msgInfo "Cloning Git"
	[ -d $pkgName ] && rm -rf $pkgName
	git clone https://aur.archlinux.org/${pkgName}.git
	chmod a+rw -R $pkgName

	if [ ! -f ${pkgName}/PKGBUILD ]; then
		_msgAlert "${pkgName} not found!"
		rm -r $pkgName
		echo; exit 1
	fi
}

####################################################################################################
###                                       BUILD                                                  ###
####################################################################################################

function _bootstrapChroot() {
	_msgInfo "Bootstraping chroot"

	chroot="/pkgRoot"
	[ -d $chroot ] && rm -rf $chroot

	_msg "Pacman update"
	if [ "$pkgType" == "pkg-a" ]; then
		pacman --config ../utils/pacman_update.conf -Sy #1> /dev/null
	else
		pacman --config ../utils/pacman_local.conf -Sy #1> /dev/null
	fi

	_msg "Installing needed dependencies"
	pacman --config ../utils/pacman_local.conf --noconfirm --needed -Sy devtools git 1> /dev/null

	_msg "Creating chroot"
	mkdir -p $chroot

	if [ "$pkgType" == "pkg-a" ]; then
		mkarchroot -C ../utils/pacman_update.conf ${chroot}/root base-devel 1> /dev/null
		cp ../utils/pacman_update.conf ${chroot}/root/etc/pacman.conf
	else
		mkarchroot -C ../utils/pacman_local.conf ${chroot}/root base-devel 1> /dev/null
		cp ../utils/pacman_local.conf ${chroot}/root/etc/pacman.conf
	fi
}

function _buildPKG() {
	_msgInfo "Preparing ${pkgName} for build"
	cd $pkgName

	[ -f build.sh ] && _msg 'Running local build.sh' && . build.sh

	_msg "Spawning chroot"
	if [ "$pkgType" == "pkg-a" ]; then
		arch-nspawn -C ../../utils/pacman_update.conf $chroot/root pacman -Syu 1> /dev/null
	else
		arch-nspawn -C ../../utils/pacman_local.conf $chroot/root pacman -Syu 1> /dev/null
	fi

	_msgInfo "Building..."
	makechrootpkg -c -r $chroot #1> /dev/null
}

function _checkBuild() {
	if [ ! -f ${pkgName}*.pkg.tar.zst ]; then
		_msgAlert "Final .pkg file not found!"
		_msgAlert "Build Error!"
		echo; exit 2
	fi
}

function _addToRepo() {
	_msgInfo "Adding ${pkgName} to ${repoName}"
	cd ../../

	[ ! -d ${repoName} ] && mkdir -p ${repoName}

	_repoSyncDown

	_msg "Moving PKG to local Repo"
	mv -vf ${pkgType}/${pkgName}/${pkgName}*.pkg.tar.zst "${repoName}/"
	_repoAddSingle $pkgName
	_repoSyncUp
}

function _finishUp() {
	_msgInfo "Finishing up"

	_msg "Cleaning up"
	rm -rf $chroot

	_msg "Updating Pacman..."
	pacman -Sy 1> /dev/null
	echo; pacman -Ss $pkgName
	pkgInstalled="$(pacman -Ss $pkgName)"
	[ ! -n pkgInstalled ] && _msgAlert "Something went bad =/"
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

[ ! $1 ] && _msgAlert "Missing PKG name!" && exit 2
pkgName=$2
cd $pkgType

if [ "$pkgType" == "pkg-a" ]; then
	_checkVersion
	_gitpkg
fi

_msgOk "${pkgName} build will start"

_bootstrapChroot
_buildPKG
_checkBuild
_addToRepo
_finishUp

echo; _msgOk "Finished ${pkgName}"; exit 1
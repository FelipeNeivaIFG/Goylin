#!/bin/bash

set -u # Unbound Variables == exit
set -e # Error == exit
set -o pipefail # Error on pipe end == exit

####################################################################################################
###                                        Source                                                ###
####################################################################################################

source utils/gMsg.sh

repoUser="suporte"
repoSrv="10.11.0.111"
repoRemotePath="/var/www/html/"

####################################################################################################
###                                        HELP                                                  ###
####################################################################################################

function _help() {
	echo
	_msgAlert "Flags:"
	_msg "-a: AUR PKGs"
	_msg "-g: Goylin PKGs"
	echo

	exit 0
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

	pacman --config ../utils/pacman_local.conf -Syy #1> /dev/null

	_msg "Creating chroot"
	mkdir -p $chroot

	mkarchroot -C ../utils/pacman_local.conf ${chroot}/root base-devel #1> /dev/null
	cp ../utils/pacman_local.conf ${chroot}/root/etc/pacman.conf
}

function _buildPKG() {
	_msgInfo "Preparing ${pkgName} for build"
	cd $pkgName

	[ "$pkgType" != "pkg-a" ] && [ -f build.sh ] && _msg 'Running local build.sh' && . build.sh

	_msg "Spawning chroot"
	arch-nspawn -C ../../utils/pacman_local.conf $chroot/root pacman -Syu --disable-download-timeout #1> /dev/null

	_msgInfo "Building..."
	makechrootpkg -c -r $chroot #1> /dev/null
}

function _checkBuild() {
	if [ ! -f ${pkgName}*.pkg.tar.zst ]; then
		_msgAlert "Final .pkg file not found!"
		_msgAlert "Build Error!"
		echo; exit 1
	fi
}

function _addToRepo() {
	_msgInfo "Adding ${pkgName} to ${repoName}"
	cd ../../

	[ ! -d ${repoName} ] && mkdir -p ${repoName}

	_msg "Syncing server repository to local"
	wget -qr -np -nH --cut-dirs=1 -N -P $repoName http://${repoSrv}/${repoName}

	_msg "Removing Old Version"
	[ -f ${repoName}/${pkgName}*.pkg.* ] && rm -v ${repoName}/${pkgName}*.pkg.*

	_msg "Moving PKG to local Repo"
	mv -f ${pkgType}/${pkgName}/${pkgName}*.pkg.tar.zst ${repoName}

	_msg "Adding $pkgName to Repo"
	[ ! -f ${repoName}/${repoName}.db.tar.gz ] && touch ${repoName}/${repoName}.db.tar.gz
	repo-add ${repoName}/${repoName}.db.tar.gz ${repoName}/${pkgName}*.pkg.tar.zst

	_msgInfo "Syncing local repository to server"
	rsync -aru --delete --human-readable --progress "${repoName}" "${repoUser}"@"${repoSrv}":"${repoRemotePath}"
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
	repoName="goylin-repo-aur"
	_checkVersion
	_gitpkg
else
	repoName="goylin-repo-g"
fi

_msgOk "${pkgName} build will start"

_bootstrapChroot
_buildPKG
_checkBuild
_addToRepo
_finishUp

echo; _msgOk "Finished ${pkgName}"; exit 1
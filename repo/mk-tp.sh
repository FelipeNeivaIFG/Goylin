#!/bin/bash

# set -u # Unbound Variables == exit
set -e # Error == exit
# set -o pipefail # Error on pipe end == exit

####################################################################################################
###                                       MSG                                                    ###
####################################################################################################

function _msgAlert() { 
    echo -e "\e[1;31m !: ${1} \e[0m"
}
function _msg() {
    echo -e "\e[1;34m >: ${1} \e[0m"
}
function _msgInfo() {
    echo -e "\e[1;33m #: ${1} \e[0m"
}
function _msgOk() {
    echo -e "\e[1;32m $: ${1} \e[0m"
}

####################################################################################################
###                                       BUILD                                                  ###
####################################################################################################

function _checkVersion() {
    _msgInfo 'Comparing local and AUR version'
    
    if [ -f ./${pkgName}/PKGBUILD ]; then
        source ./${pkgName}/PKGBUILD
        localVersion="${pkgver}-${pkgrel}"

        aurInfo=$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg=$pkgName")
        aurVersion=$(echo "$aurInfo" | grep -oP '"Version":"\K[^"]+')

        _msg "Local: ${localVersion}"
        _msg "AUR: ${aurVersion}"
    fi

    if [[ -n "$localVersion" && "$localVersion" == "$aurVersion" ]]; then
        echo; _msgOk "${pkgName} is updated." && exit 1
    fi
}

function _gitpkg() {
    echo; _msgInfo 'Cloning Git'; echo
    [ -d $pkgName ] && rm -rf $pkgName
    git clone https://aur.archlinux.org/${pkgName}.git

    if [ ! -f ${pkgName}/PKGBUILD ]; then
        echo; _msgAlert "${pkgName} not found!"
        rm -r $pkgName
        echo; exit 1
    fi
}

function _bootstrapChroot() {
    _msgInfo 'Bootstraping chroot'; echo

    chroot="/pkgRoot"
    [ -d $chroot ] && sudo rm -rf $chroot

    _msg 'Syncing repo'
    sudo pacman -Sy 1> /dev/null
    _msg 'Installing needed dependencies'
    sudo pacman --noconfirm --needed -S devtools git 1> /dev/null

    _msg 'Creating chroot'
    mkdir -p ${chroot}
    mkarchroot -C ../pacman_update.conf ${chroot}/root base-devel 1> /dev/null
    sudo cp ../pacman_update.conf ${chroot}/root/etc/pacman.conf
}

function _buildPKG() {
    echo; _msgInfo "Preparing ${pkgName} for build"; echo
    cd $pkgName

    [ -f build.sh ] && _msg 'Running local build.sh' && . build.sh

    _msg 'Spawning chroot'
    arch-nspawn $chroot/root pacman -Syu 1> /dev/null

    echo; _msgInfo 'Building...'; echo
    makechrootpkg -c -r $chroot #1> /dev/null
}

function _checkBuild() {
    if [ ! -f ${pkgName}*.pkg.tar.zst ]; then
    echo; _msgAlert 'Final .pkg file not found!'
    _msgAlert 'Build Error!'
    echo; exit 2
    fi
}

function _addToRepo() {
    echo; _msgInfo "Adding ${pkgName} to ${repoName}"; echo

    repoName='goylin-repo'
    repoUser="suporte"
    repoLocalPath="../../"
    repoSrv="10.11.0.111"
    repoRemotePath="/var/www/html/"

    [ ! -d ${repoLocalPath} ] && sudo mkdir -p ${repoLocalPath}

    _msg "Syncing server repository to local"
    sudo rsync -aruz "${repoUser}"@"${repoSrv}":"${repoRemotePath}/${repoName}" $repoLocalPath --progress

    _msg "Moving PKG to local Repo"
    sudo mv -vf ${pkgName}*.pkg.tar.zst "${repoLocalPath}/${repoName}"
    sudo repo-add ${repoLocalPath}/${repoName}/${repoName}.db.tar.gz ${repoLocalPath}/${repoName}/${pkgName}*.pkg.tar.zst

    _msg "Syncing local repository to server"
    sudo rsync -aruz "${repoLocalPath}/${repoName}" "${repoUser}"@"${repoSrv}":"${repoRemotePath}" --progress
}

function _finishUp() {
    echo; _msgInfo "Finishing up"; echo

    _msg 'Cleaning up'
    sudo rm -rf $chroot

    _msg "Updating Pacman..."
    sudo pacman -Sy 1> /dev/null
    echo; pacman -Ss $pkgName
    pkgInstalled="$(pacman -Ss $pkgName)"
    [ ! -n pkgInstalled ] && _msgAlert "Something went bad =/"
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################
[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

[ ! $1 ] && _msgAlert 'Missing PKG name!' && exit 2
pkgName=$1
cd pkg-tp

_checkVersion
_gitpkg
echo; _msgOk "${pkgName} build will start"; echo

_bootstrapChroot
_buildPKG
_checkBuild
_addToRepo
_finishUp

echo; _msgOk "Finished ${pkgName}"; exit 1
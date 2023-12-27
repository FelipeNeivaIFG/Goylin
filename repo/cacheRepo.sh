#!/bin/bash
# set -u # Unbound Variables == exit
set -e # Error == exit
# set -o pipefail # Error on pipe end == exit

####################################################################################################
###                                        MSGs                                                  ###
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
###                                       INIT                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

_msgInfo "Starting repository caching setup..."
repoName="goylin-repo"
repoUser="suporte"
repoLocalPath="${repoName}"
repoSrv="10.11.0.111"
repoRemotePath="/var/www/html/"

echo; _msg "Syncing server repository to local"
sudo rsync -aruz "${repoUser}"@"${repoSrv}":"${repoRemotePath}/${repoName}" . --progress

echo; _msg "Ensuring clean blankdb"
[ -d blankdb ] && sudo rm -rf blankdb
sudo mkdir -p blankdb

echo; _msg "Getting better mirrors"
sudo reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist 1> /dev/null

echo; _msgInfo "Caching PKGs from pkg-list.txt"
sudo pacman -Syyw --config pacman_update.conf --noconfirm --cachedir $repoLocalPath --dbpath blankdb - < pkg-list.txt
sudo repo-add ${repoLocalPath}/${repoName}.db.tar.gz ${repoLocalPath}/*.pkg.tar.zst
[ -f ${repoLocalPath}/*.pkg.tar.xz ] && sudo repo-add ${repoLocalPath}/${repoName}.db.tar.gz ${repoLocalPath}/*.pkg.tar.xz

echo; _msg "Syncing local repository to server"
sudo rsync -aruz "${repoLocalPath}" "${repoUser}"@"${repoSrv}":"${repoRemotePath}" --progress

echo; _msg "Clean up blankdb"
sudo rm -r blankdb

echo; _msgInfo "Updating Pacman"
sudo pacman -Syy

exit 1
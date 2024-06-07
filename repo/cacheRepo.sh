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
###                                        Help                                                  ###
####################################################################################################

function _help() {
	_msgInfo "Cache Repo flags:"

	_msgOpt "-c : Start Clean Repo"

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
###                                       INIT                                                   ###
####################################################################################################

clear
[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

_msgInfo "Caching..."

_repoBlankDb
if [ $newRepo -eq 1 ]; then
    _repoBetterMirrors
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
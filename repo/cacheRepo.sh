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
###                                       INIT                                                   ###
####################################################################################################

clear
[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

_msgInfo "Caching..."

_repoBlankDb
_repoBetterMirrors
_repoSyncDown
_repoCacheList
_repoAddPKGs
_repoSyncUp
_repoCleanUp

_msg "Updating Pacman"
pacman -Syy 1> /dev/null

_msgOk "PKGs cached!"
_msgOk "\,,/_(o.O)_\,,/"

exit 1
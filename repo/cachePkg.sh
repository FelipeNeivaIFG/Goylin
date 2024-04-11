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
pkgName=$1

_msgInfo "Caching..."

_repoSyncDown
_repoBlankDb
# _repoBetterMirrors
_repoCachePKG $pkgName
_repoAddPKGs
_repoSyncUp
_repoCleanUp

_msg "Updating Pacman"
pacman -Syy 1> /dev/null

_msgOk "PKGs cached!"
_msgOk "\,,/_(o.O)_\,,/"

exit 1
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
###                                        Settings                                              ###
####################################################################################################

# Values set by goylin_installer.sh
target=_TARGET_
targetType=_TARGETTYPE_
profile=_PROFILE_
cpuType=_CPUTYPE_
gRootPasswd=_ROOTPASSWD_
gAdminPasswd=_ADMINPASSWD_
gRadioPaswd=_RADIOPASSWD_
gGremioPasswd=_GREMIOPASSWD_

  
function _configSys() {
  echo; _msgInfo '###  Base Config  ###'; echo

  _msg 'Config system'
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  locale-gen

  [ "$targetType" == '1' ] && systemctl enable fstrim.timer

  _msg 'Config Pacman'
  pacman --noconfirm -Syu 1> /dev/null
}

function _configGRUB() {
  echo; _msgInfo '###   GRUB   ###'; echo

  pacman --noconfirm --needed -S grub 1> /dev/null
  grub-install --target=i386-pc /dev/${target} 1> /dev/null
  grub-mkconfig -o /boot/grub/grub.cfg 1> /dev/null
}

function _configUsers() {
  echo; _msgInfo '###   Users & groups   ###'; echo

  echo -e "${gRootPasswd}\n${gRootPasswd}" | passwd root
  useradd -G wheel admin
  echo -e "${gAdminPasswd}\n${gAdminPasswd}" | passwd admin

  groupadd -r nopasswdlogin
  useradd -G nopasswdlogin guest
  chfn -f "Público" guest 1> /dev/null
}

####################################################################################################
###                                      Base PKGs                                               ###
####################################################################################################

function _pkgs() {
  echo; _msgInfo '###   PKGs   ###'; echo

  case $cpuType in
    1) _msg 'AMD'; pacman --noconfirm --needed --overwrite "*" -S g-amd 1> dev/null;;
    *) _msg 'Intel'; pacman --noconfirm --needed --overwrite "*" -S g-intel 1> /dev/null;;
  esac
  
  _msg 'Core'
  pacman --noconfirm --needed --overwrite "*" -S g-core 1> /dev/null

  _msg 'AD'
  pacman --noconfirm --needed --overwrite "*" -S g-ad 1> /dev/null

  _msg 'Desktop'
  pacman --noconfirm --needed --overwrite "*" -S g-desktop 1> /dev/null

  _msg 'Backgrounds'
  pacman --noconfirm --needed --overwrite "*" -S g-backgrounds 1> /dev/null

  _msg 'Plasma'
  pacman --noconfirm --needed --overwrite "*" -S g-plasma 1> /dev/null

  _msg 'i3'
  pacman --noconfirm --needed --overwrite "*" -S g-i3 1> /dev/null

  _msg 'App: Base'
  pacman --noconfirm --needed --overwrite "*" -S gapp-base 1> /dev/null

  _msg 'Profile: Base'
  pacman --noconfirm --needed --overwrite "*" -S gp-base 1> /dev/null
}

####################################################################################################
###                                    Profiles                                                  ###
####################################################################################################

function _pAdm() {
  echo; _msgInfo '###   Profile: Administrative   ###'; echo
  
  _msg 'Profile'
  pacman --noconfirm --needed --overwrite "*" -S gp-adm 1> /dev/null

  sed -i "s/Core/Administrative/g" /usr/lib/os-release
}

function _pCinema() {
  echo; _msgInfo '###   Profile: Cinema   ###'; echo

  _msg 'App: VFX'
  pacman --noconfirm --needed --overwrite "*" -S gapp-vfx 1> /dev/null

  _msg 'App: Audio'
  pacman --noconfirm --needed --overwrite "*" -S gapp-audio 1> /dev/null

  _msg 'App: Image'
  pacman --noconfirm --needed --overwrite "*" -S gapp-image 1> /dev/null

  _msg 'App: Video'
  pacman --noconfirm --needed --overwrite "*" -S gapp-video 1> /dev/null

  _msg 'App: Write'
  pacman --noconfirm --needed --overwrite "*" -S gapp-write 1> /dev/null

  _msg 'Profile'
  pacman --noconfirm --needed --overwrite "*" -S gp-cinema 1> /dev/null

  sed -i "s/Core/Cinema/g" /usr/lib/os-release
}

function _pGeo() {
  echo; _msgInfo '###   Profile: Geo   ###'; echo

  _msg 'App: Geo'
  pacman --noconfirm --needed --overwrite "*" -S gapp-geo 1> /dev/null

  _msg 'App: Cad'
  pacman --noconfirm --needed --overwrite "*" -S gapp-cad 1> /dev/null
  
  _msg 'Profile'
  pacman --noconfirm --needed --overwrite "*" -S gp-geo 1> /dev/null

  sed -i "s/Core/Geotecnologia/g" /usr/lib/os-release
}

function _pRadio() {
  echo; _msgInfo '###   Profile: Radio   ###'; echo

  _msg 'App: Audio'
  pacman --noconfirm --needed --overwrite "*" -S gapp-audio 1> /dev/null

  _msg 'App: Video'
  pacman --noconfirm --needed --overwrite "*" -S gapp-video 1> /dev/null

  _msg 'App: Image'
  pacman --noconfirm --needed --overwrite "*" -S gapp-image 1> /dev/null

  _msg 'Profile'
  pacman --noconfirm --needed --overwrite "*" -S gp-radio 1> /dev/null

  useradd radiovozzes
  echo -e "$gRadioPaswd\n$gRadioPaswd" | passwd radiovozzes
  chfn -f "Radio Vozzes" radiovozzes
  sed -i "s/Core/Radio/g" /usr/lib/os-release
}

function _pGremio() {
  echo; _msgInfo '###   Profile: Gremio   ###'; echo

  _msg 'App: Geo'
  pacman --noconfirm --needed --overwrite "*" -S gapp-geo 1> /dev/null

  _msg 'App: Code'
  pacman --noconfirm --needed --overwrite "*" -S gapp-code 1> /dev/null

  _msg 'App: Cad'
  pacman --noconfirm --needed --overwrite "*" -S gapp-cad 1> /dev/null

  _msg 'App: VFX'
  pacman --noconfirm --needed --overwrite "*" -S gapp-vfx 1> /dev/null

  _msg 'App: Audio'
  pacman --noconfirm --needed --overwrite "*" -S gapp-audio 1> /dev/null

  _msg 'App: Video'
  pacman --noconfirm --needed --overwrite "*" -S gapp-video 1> /dev/null

  _msg 'App: Image'
  pacman --noconfirm --needed --overwrite "*" -S gapp-image 1> /dev/null
  
  _msg 'App: Game'
  pacman --noconfirm --needed --overwrite "*" -S gapp-game 1> /dev/null

  _msg 'App: Write'
  pacman --noconfirm --needed --overwrite "*" -S gapp-write 1> /dev/null

  _msg 'App: GameDev'
  pacman --noconfirm --needed --overwrite "*" -S gapp-gamedev 1> /dev/null

  _msg 'Profile'
  pacman --noconfirm --needed --overwrite "*" -S gp-gremio 1> /dev/null

  useradd gremio
  echo -e "${gGremioPasswd}\n${gGremioPasswd}" | passwd gremio
  chfn -f "Grêmio" gremio
  sed -i "s/Core/Gremio/g" /usr/lib/os-release
}

function _pWriter() {
  echo; _msgInfo '###   Profile: Writer   ###'; echo

  _msg 'App: Write'
  pacman --noconfirm --needed --overwrite "*" -S gapp-write 1> /dev/null

  _msg 'Profile'
  pacman --noconfirm --needed --overwrite "*" -S gp-writer 1> /dev/null

  sed -i "s/Core/Writer/g" /usr/lib/os-release
}

function _pLibrary() {
  echo; _msgInfo '###   Profile: Library   ###'; echo

  _msg 'App: Geo'
  pacman --noconfirm --needed --overwrite "*" -S gapp-geo 1> /dev/null

  _msg 'App: Code'
  pacman --noconfirm --needed --overwrite "*" -S gapp-code 1> /dev/null

  _msg 'App: Cad'
  pacman --noconfirm --needed --overwrite "*" -S gapp-cad 1> /dev/null

  _msg 'App: VFX'
  pacman --noconfirm --needed --overwrite "*" -S gapp-vfx 1> /dev/null

  _msg 'App: Audio'
  pacman --noconfirm --needed --overwrite "*" -S gapp-audio 1> /dev/null

  _msg 'App: Video'
  pacman --noconfirm --needed --overwrite "*" -S gapp-video 1> /dev/null

  _msg 'App: Image'
  pacman --noconfirm --needed --overwrite "*" -S gapp-image 1> /dev/null
  
  _msg 'App: Write'
  pacman --noconfirm --needed --overwrite "*" -S gapp-write 1> /dev/null

  _msg 'App: GameDev'
  pacman --noconfirm --needed --overwrite "*" -S gapp-gamedev 1> /dev/null

  sed -i "s/Core/Library/g" /usr/lib/os-release
}

function _pLaptop() {
  echo; _msgInfo '###   Profile: Laptop   ###'; echo

  _msg 'Laptop'
  pacman --noconfirm --needed --overwrite "*" -S g-laptop 1> /dev/null

  _msg 'Profile: adm'
  pacman --noconfirm --needed --overwrite "*" -S gp-adm 1> /dev/null

  _configUsers
  sed -i "s/Core/Laptop/g" /usr/lib/os-release
}

function _getProfile() {
  case $profile in
    1)
      _pAdm;;
    2)
      _pCinema;;
    3)
      _pGeo;;
    4)
      _pRadio;;
    5)
      _pGremio;;
    6)
      _pWriter;;
    7)
      _pLibrary;;
    8)
      _pLaptop;;
    *)
      ;;
esac
}

####################################################################################################
###                                     GCHROOT INIT                                             ###
####################################################################################################

_configSys
_configUsers
_pkgs
sync
_getProfile
_configGRUB

echo; _msgInfo '###   mkinitcpio   ###'; echo
mkinitcpio -P 1> /dev/null

echo; _msgOk '###   Exiting CHROOT   ###'
sync
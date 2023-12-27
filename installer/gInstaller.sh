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

function _msgLogo() {
  _msgOk "  ██████╗  ██████╗ ██╗   ██╗██╗     ██╗███╗   ██╗ "
  _msgOk " ██╔════╝ ██╔═══██╗╚██╗ ██╔╝██║     ██║████╗  ██║ "
  _msgOk " ██║  ███╗██║   ██║ ╚████╔╝ ██║     ██║██╔██╗ ██║ "
  _msgOk " ██║   ██║██║   ██║  ╚██╔╝  ██║     ██║██║╚██╗██║ "
  _msgOk " ╚██████╔╝╚██████╔╝   ██║   ███████╗██║██║ ╚████║ "
  _msgOk "  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝╚═╝  ╚═══╝ "
}

function _msgWelcome() {
    clear; echo
    _msgLogo
    _msgOk "Version: ${goylinVersion}"
    _msgOk "Goylin Installer"; echo
}

####################################################################################################
###                               Bootstrap Installer                                            ###
####################################################################################################

function _bootstrap() {
  echo; _msgInfo '###   Bootstraping Installer  ###'; echo
  
  _msg 'Pacman Setup'
  pacman-key --init 1> /dev/null
  pacman-key --populate archlinux 1> /dev/null
  pacman -Sy --noconfirm --needed reflector #1> /dev/null
  reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist #1> /dev/null
  pacman -Su --noconfirm 1> /dev/null
  
  _msg 'Checking installer Deppendencies'
  pacman -S --noconfirm --needed arch-install-scripts dosfstools e2fsprogs base-devel mtools #1> /dev/null
}

####################################################################################################
###                                        Setup                                                 ###
####################################################################################################

function _setTarget() {
    protectTarget=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /))
    
    _msg 'Available Target devices:'
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | awk '$3 == "disk"' | grep -v $protectTarget
    
    echo; _msg 'Target name? ( eg. sdx )'
    read -p '<: ' -e target
    
    [ ! $target ] && _msgAlert 'Target Device Required!' && exit
    [ $target == $protectTarget ] && _msgAlert 'WTF!? This device belongs to current system!' && exit
    targetPath="/dev/${target}"
    [ ! -b $targetPath ] && _msgAlert 'Null device!' && exit
    
    echo
}

function _setTargetType() {
  _msg "Target type:"
  _msgOk '1) SSD'
  _msgOk '*) HDD'
  read -p '?: ' -e targetType; echo
}

function _setKeepHome() {
  _msg 'Keep Home Partition and Update Goylin? [y/N]'
  read -p '?: ' -e keepHome; echo
}

function _setCPU() {
  _msg 'ucode CPU:'
  _msgOk '1) AMD'
  _msgOk '*) Intel'
  read -p '?: ' -e cpuType; echo
}

function _setProfile() {
  _msg 'Profile:'
  _msgOk '1) Administrative'
  _msgOk '2) Cinema'
  _msgOk '3) Geo'
  _msgOk '4) Radio'
  _msgOk '5) Gremio'
  _msgOk '6) Writer'
  _msgOk '7) Library'
  _msgOk '8) Laptop'
  _msgOk '*) Base'
  read -p '?: ' -e profile; echo
}

function _setup() {
  _setTarget
  _setTargetType
  _setKeepHome
  _setCPU
  _setProfile 
}

####################################################################################################
###                                       Target                                                 ###
####################################################################################################

function _prepUmount() {
  _msg "Unmounting Target"
  sync
  [[ $(mount | grep "/mnt") ]] && umount -Rl /mnt
  [[ $(mount | grep "${target}1") ]] && umount -Rl "/dev/${target}1"
  [[ $(mount | grep "${target}2") ]] && umount -Rl "/dev/${target}2"
  [[ $(mount | grep "${target}3") ]] && umount -Rl "/dev/${target}3"
  [[ $(mount | grep "${target}4") ]] && umount -Rl "/dev/${target}4"
  swapoff -a
}

function _prepWipe(){
  _msg "Wiping target"
  wipefs -af $targetPath
  dd if=/dev/zero of=$targetPath bs=1M count=1024
  sync
}

function _prepMount() {
  _msg 'Mounting'
  swapon "${targetPath}2"
  mount "${targetPath}3" /mnt
  mkdir -p /mnt/{boot,home}
  mount "${targetPath}4" /mnt/home
  mount "${targetPath}1" /mnt/boot
}

function _prepGRUB() {
  grubSize='+250M'
  swapSize='+16G'
  systemSize='+50G'

  _msg 'Partitioning (BIOS) (SWAP; /; /boot; /home)'
  (
    echo 'o'
    echo 'n'; echo 'p'; echo; echo; echo $grubSize; echo 'a';
    echo 'n'; echo 'p'; echo; echo; echo $swapSize
    echo 't'; echo '2'; echo 'swap'
    echo 'n'; echo 'p'; echo; echo; echo $systemSize
    echo 'n'; echo 'p'; echo; echo
    echo 'w';
  ) | fdisk $targetPath 1> /dev/null
  sync

  _msg "Formating (ext4)"
  mkfs.ext4 -F "${targetPath}1" 1> /dev/null
  mkfs.ext4 -F "${targetPath}3" 1> /dev/null
  mkfs.ext4 -F "${targetPath}4" 1> /dev/null
  mkswap "${targetPath}2" 1> /dev/null
  sync

  _prepMount
}

function _prepUpdate() {
  _msg "Formating (ext4) - Keeping /home"
  mkfs.ext4 -F "${targetPath}1" 1> /dev/null
  mkfs.ext4 -F "${targetPath}3" 1> /dev/null
  mkswap "${targetPath}2" 1> /dev/null
  sync

  _prepMount
}

function _prepTarget() {
  echo; _msgInfo '###   Preparing Target   ###'; echo
  _prepUmount
  if [ "$keepHome" == 'y' ] || [ "$keepHome" == 'Y' ]; then
    _prepUpdate
  else
    _prepWipe
    _prepGRUB
  fi
}

####################################################################################################
###                                  System Install                                              ###
####################################################################################################

function _installCore() {
  echo; _msgInfo '###   Instaling Goylin   ###'; echo
  
  _msg 'Pacstraping'
  pacstrap -K -C root/etc/pacman.conf /mnt base base-devel linux linux-firmware mkinitcpio 1> /dev/null
  sync

  _msg 'Installing /gchroot'
  install -Dm 700 -t /mnt gchroot.sh
  sync
  sed -i "s/_TARGET_/${target}/g" /mnt/gchroot.sh
  sed -i "s/_TARGETTYPE_/${targetType}/g" /mnt/gchroot.sh
  sed -i "s/_PROFILE_/${profile}/g" /mnt/gchroot.sh
  sed -i "s/_CPUTYPE_/${cpuType}/g" /mnt/gchroot.sh
  sed -i "s/_ROOTPASSWD_/${gRootPasswd}/g" /mnt/gchroot.sh
  sed -i "s/_ADMINPASSWD_/${gAdminPasswd}/g" /mnt/gchroot.sh
  sed -i "s/_RADIOPASSWD_/${gRadioPasswd}/g" /mnt/gchroot.sh
  sed -i "s/_GREMIOPASSWD_/${gGremioPasswd}/g" /mnt/gchroot.sh
  
  _msg 'Installing /etc'
  install -Dm 644 -t /mnt/etc root/etc/hostname
  install -Dm 644 -t /mnt/etc root/etc/hosts
  install -Dm 644 -t /mnt/etc root/etc/locale.conf
  install -Dm 644 -t /mnt/etc root/etc/locale.gen
  install -Dm 644 -t /mnt/etc root/etc/pacman.conf
  sync

  _msg 'Generating fstab'
  genfstab -U /mnt > /mnt/etc/fstab
  if [ "$targetType" == '1' ]; then
    sed -i "s/relatime/noatime/g" /mnt/etc/fstab
  fi
}

function _chroot() {
  echo; _msgOk '###   CHROOT   ###'
  arch-chroot /mnt /gchroot.sh
  rm -f /mnt/gchroot.sh
  echo
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit

goylinVersion="24.1"
source gpasswd.sh

timedatectl set-ntp true
hwclock --systohc

# while getopts 'b' inFlag; do
#   case "$inFlag" in
#     b) _bootstrap;;
#   esac
# done

_msgWelcome
_setup
_prepTarget
_installCore
_chroot
_prepUmount

sync
echo; _msgOk 'Goylin is Installed!'
_msgOk '\,,/_(o.O)_\,,/'; echo
exit 1
#!/bin/bash

set -u # Unbound Variables == exit
set -e # Error == exit
set -o pipefail # Error on pipe end == exit

####################################################################################################
###                                        Source                                                ###
####################################################################################################

source utils/gMsg.sh
source utils/gPasswd.sh
source utils/installConf.sh

####################################################################################################
###                                        Help                                                  ###
####################################################################################################

function _help() {
	_msgInfo "Goylin installer flags:"
	_msgOpt "-s : Skip bootstrap."
	_msgOpt "-d : Use default install configuration."
	echo; exit 0
}

####################################################################################################
###                                        Flags                                                 ###
####################################################################################################

while getopts "sdh" opt; do
    case $opt in
        s) skipBootstrap=1 ;;
        d) useDefaultConf=1 ;;
		*) _help ;;
    esac
done

####################################################################################################
###                               Bootstrap Installer                                            ###
####################################################################################################

function _bootstrap() {
	_msgInfo "###   Bootstraping Installer  ###"

	_msg "Time Sync"
	timedatectl set-ntp true
	hwclock --systohc
	
	_msg "Pacman Sync"
	pacman -Sy --noconfirm --config utils/pacman_local.conf 1> /dev/null
	
	# _msg "Checking installer Deppendencies"
	# pacman -S --noconfirm --needed arch-install-scripts dosfstools e2fsprogs base-devel mtools 1> /dev/null

	return 0
}

####################################################################################################
###                                        Setup                                                 ###
####################################################################################################

function _setTarget() {
	# Protect Target won't work on Live-USB installation
	protectTarget=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /))

	_msg "Available Target devices:"
	lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | awk '$3 == "disk"' | grep -v $protectTarget

	echo; _msg "Target name? ( eg. sdx )"
	read -p "?: " -e target

	[ "$target" == "" ] && _msgAlert "Target Device Required!" && exit 1
	[ "$target" == "$protectTarget" ] && _msgAlert 'WTF!? This device belongs to current system!' && exit 1
	[ ! -b "/dev/$target" ] && _msgAlert 'Null device!' && exit 1

	return 0
}

function _setTargetType() {
	_msg "Target type:"
	_msgOpt "1) HDD"
	_msgOpt "*) SSD"
	read -p "?: " -e optTargetType

	case $optTargetType in
		1) targetType="hdd" ;;
		*) targetType="ssd" ;;
	esac

	return 0
}

function _setKeepHome() {
	_msg "Keep Home Partition and Update Goylin? (y/N)"
	read -p "?: " -e optKeepHome
	[[ "$optKeepHome" == "y" || "$optKeepHome" == "Y" ]] && keepHome=1 

	return 0
}

function _setCPU() {
	_msg "CPU:"
	_msgOpt "1) AMD"
	_msgOpt "*) Intel"
	read -p '?: ' -e optCpuType

	case $optCpuType in
		1) cpuType="amd" ;;
		*) cpuType="intel" ;;
	esac

	return 0
}

function _setProfile() {
	_msg "Profile:"
	_msgOpt "1) Administrative"
	_msgOpt "2) Cinema"
	_msgOpt "3) Geotec"
	_msgOpt "4) Radio"
	_msgOpt "5) Gremio"
	_msgOpt "6) Library"
	_msgOpt "7) Laptop"
	_msgOpt "*) Base"
	read -p '?: ' -e optProfile

  	case $optProfile in
		1) profile="adm" ;;
		2) profile="cine" ;;
		3) profile="geo" ;;
		4) profile="radio" ;;
		5) profile="gremio" ;;
		6) profile="lib" ;;
		7) profile="laptop" ;;
		*) profile="base" ;;
	esac

	return 0
}

function _setConfirm() {
	_msgAlert "Confirm settings: (y/N)"
	_msgOpt "Target: $target"
	_msgOpt "Type: $targetType"
	_msgOpt "KeepHome: $keepHome"
	_msgOpt "CPU: $cpuType"
	_msgOpt "Profile: $profile"
	
	_msgOk "Confirm (y/N)"
	read -p "?: " -e setConfirm
	[ ! "$setConfirm" == "y" ] && _msgAlert "Aborting" && exit 1

	return 0
}

function _setup() {
	_msgInfo "###   Install settings  ###"

	_setTarget

	if [ "$useDefaultConf" -eq 0 ]; then
		_setTargetType
		_setKeepHome
		_setCPU
		_setProfile
	else
		_setProfile
	fi

	_setConfirm
}

####################################################################################################
###                                       Target                                                 ###
####################################################################################################

function _prepUmount() {
	_msg "Unmounting Target"
	sync
	[[ $(mount | grep "/mnt") ]] && umount -lR /mnt
	[[ $(mount | grep "${target}1") ]] && umount -lR "/dev/${target}1"
	[[ $(mount | grep "${target}2") ]] && umount -lR "/dev/${target}2"
	[[ $(mount | grep "${target}3") ]] && umount -lR "/dev/${target}3"
	[[ $(mount | grep "${target}4") ]] && umount -lR "/dev/${target}4"
	[[ $(swapon | grep "${target}2") ]] && swapoff "/dev/${target}2"
	sync
}

function _prepWipe(){
	_msg "Wiping target"

	wipefs -af /dev/$target* 1> /dev/null
	dd if=/dev/zero of=/dev/$target bs=1M count=1024
}

function _prepPartBIOS() {
	_msg 'Partitioning (BIOS) (SWAP; /; /boot; /home)'

	(
		echo 'o'
		echo 'n'; echo 'p'; echo; echo; echo $grubSize; echo 'a';
		echo 'n'; echo 'p'; echo; echo; echo $swapSize
		echo 't'; echo '2'; echo 'swap'
		echo 'n'; echo 'p'; echo; echo; echo $systemSize
		echo 'n'; echo 'p'; echo; echo
		echo 'w';
	) | fdisk /dev/$target 1> /dev/null
}

function _prepFormat() {
	_msg "Formating"

	mkfs.ext4 -q "/dev/${target}1"
	mkfs.ext4 -q "/dev/${target}3"
	mkfs.ext4 -q "/dev/${target}4"
	mkswap -q "/dev/${target}2"
}

function _prepFormatKeepHome() {
	_msg "Formating - Keeping /home"
	
	mkfs.ext4 -q "/dev/${target}1"
	mkfs.ext4 -q "/dev/${target}3"
	mkswap -q "/dev/${target}2"
}

function _prepMount() {
	_msg 'Mounting'

	mount /dev/${target}3 /mnt
	mkdir -p /mnt/{boot,home}

	mount /dev/${target}4 /mnt/home
	mount /dev/${target}1 /mnt/boot

	swapon /dev/${target}2

	return 0
}

function _prepCleanHomeDots () {
	_msgInfo '###   Cleaning User Dots   ###'
	[ -d /mnt/home/lost+found ] && rm -rfv /mnt/home/lost+found
	for userInHome in /mnt/home/*; do
		userHome=$(basename $userInHome)
		_msg $userHome
    	rm -rf /mnt/home/${userHome}/.*
		rm -f /mnt/home/${userHome}/Desktop/*.desktop
	done
}

function _prepTarget() {
	_msgInfo "###   Preparing Target   ###"

	_prepUmount
	if [ $keepHome -eq 1 ]; then
		_prepFormatKeepHome
	else
		_prepWipe
		_prepPartBIOS
		_prepFormat
	fi
	_prepMount
	[ $keepHome -eq 1 ] && _prepCleanHomeDots

	return 0
}

####################################################################################################
###                                  System Install                                              ###
####################################################################################################

function _instPacstrap() {
	_msg "Pacstraping"

	pacstrap -K -C utils/pacman_local.conf /mnt base linux linux-firmware mkinitcpio grub 1> /dev/null
}

_instFiles() {
	_msg "Installing files"

	install -Dm 0700 -t /mnt/gChroot gChroot.sh
	install -Dm 0700 -t /mnt/gChroot/utils utils/gMsg.sh

	echo "
#!/bin/bash
target="$target"
targetType="$targetType"
profile="$profile"
cpuType="$cpuType"
gRootPasswd="$gRootPasswd"
gAdminPasswd="$gAdminPasswd"
gRadioPasswd="$gRadioPasswd"
gGremioPasswd="$gGremioPasswd"
keepHome="$keepHome"
" >> /mnt/gChroot/utils/chrConfig.sh

	install -Dm 0644 -t /mnt/etc root/etc/hostname
	install -Dm 0644 -t /mnt/etc root/etc/hosts
	install -Dm 0644 -t /mnt/etc root/etc/locale.conf
	install -Dm 0644 -t /mnt/etc root/etc/locale.gen

	install -Dm 0644 -t /mnt/etc utils/pacman_local.conf
	mv -f /mnt/etc/pacman_local.conf /mnt/etc/pacman.conf
}

_instFstab() {
	_msg "Generating fstab"

	genfstab -U /mnt >> /mnt/etc/fstab
	sed -i '/^\/swapfile/d' /mnt/etc/fstab
	if [ "$targetType" == "ssd" ]; then
		sed -i "s/relatime/noatime/g" /mnt/etc/fstab
	fi
}

_instChroot() {
	_msgOk "###   CHROOT   ###"

	arch-chroot /mnt /gChroot/gChroot.sh

	_msg "Cleaning installer files"
	rm -r /mnt/gChroot
}

function _installGoylin() {
	_msgInfo "###   Instaling Goylin   ###"

	_instPacstrap
	_instFiles
	_instFstab
	_instChroot
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && exit

_msgWelcome

[ "$skipBootstrap" -eq 0 ] && _bootstrap

_setup
_prepTarget
_installGoylin

sync && _prepUmount
_msgDone
exit 0
#!/bin/bash

set -ue
cd "$(dirname $(readlink -f "$0"))" || exit 1

####################################################################################################
###                                        Source                                                ###
####################################################################################################

. utils/gMsg.sh
. utils/gPasswd.sh
. utils/installConf.sh

####################################################################################################
###                                        Help                                                  ###
####################################################################################################

function _help() {
	_msgInfo "Goylin installer flags:"
	_msgOpt "-d : Use default install configuration."
	_msgOpt "-l : Local install."

	echo; exit 0
}

####################################################################################################
###                                        Flags                                                 ###
####################################################################################################

while getopts "dl" opt; do
	case $opt in
		d) useDefaultConf=1;;
		l) localDevInstall=1; pacmanConf="../utils/pacman_dev.conf";;
		*) _help;;
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
	pacman -Syy --config "$pacmanConf"
	pacman-key --init --config "$pacmanConf"
	pacman-key --populate --config "$pacmanConf"

	return 0
}

####################################################################################################
###                                        Setup                                                 ###
####################################################################################################

function _setTarget() {
	[ $localDevInstall -eq 1 ] && local protectTarget=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /))

	_msg "Available Target devices:"
	if [ $localDevInstall -eq 1 ]; then
		lsblk -o NAME,SIZE,TYPE | awk '$3 == "disk"' | grep -v "$protectTarget"
	else
		lsblk -o NAME,SIZE,TYPE | awk '$3 == "disk"'
	fi

	echo; _msg "Target name? ( eg. sdx )"
	read -p "?: " -e target

	[ "$target" == "" ] && _msgAlert "Target Device Required!" && exit 1
	[ ! -b "/dev/$target" ] && _msgAlert "Null device!" && exit 1

	[ $localDevInstall -eq 1 ] && [ "$target" == "$protectTarget" ] && _msgAlert "WTF!? This device belongs to current system!" && exit 1

	echo; return 0
}

function _setTargetType() {
	_msg "Target type:"
	_msgOpt "1) HDD"
	_msgOpt "2) NVMe"
	_msgOpt "*) SSD"
	read -p "?: " -e optTargetType

	case $optTargetType in
		1) targetType="hdd";;
		2) targetType="nvme";;
		*) targetType="ssd";;
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
		1) cpuType="amd";;
		*) cpuType="intel";;
	esac

	return 0
}

function _setProfile() {
	_msg "Profile:"
	_msgOpt "1) Administrative"
	_msgOpt "2) Cinema"
	_msgOpt "3) Agro"
	_msgOpt "4) Radio"
	_msgOpt "5) Gremio"
	_msgOpt "6) Library"
	_msgOpt "*) Base"
	read -p '?: ' -e optProfile

	case $optProfile in
		1) profile="adm";;
		2) profile="cinema";;
		3) profile="agro";;
		4) profile="radio";;
		5) profile="gremio";;
		6) profile="library";;
		*) profile="base";;
	esac

	return 0
}

function _setConfirm() {
	_msgAlert "Settings:"
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
	fi

	_setProfile
	_setConfirm

	return 0
}

####################################################################################################
###                                       Target                                                 ###
####################################################################################################

function _prepHardUmount() {
	_prepUmount
	sync
	if [[ $(mount | grep "/mnt") ]]; then
		_msg "lsof KILL for umount"
		lsof | grep "/mnt" | awk '{print $2}'| xargs sudo kill
		umount -qfR /mnt
		_prepUmount
	fi

	return 0
}

function _prepUmount() {
	_msg "Unmounting Target"

	[ "$targetType" == "nvme" ] && p="p" || p=""

	sync
	[[ $(mount | grep /mnt) ]] && umount -qlfR /mnt
	[[ $(mount | grep "${target}${p}"1) ]] && umount -qlf /dev/"${target}${p}"1
	[[ $(mount | grep "${target}${p}"2) ]] && umount -qlf /dev/"${target}${p}"2
	[[ $(mount | grep "${target}${p}"3) ]] && umount -qlf /dev/"${target}${p}"3
	[[ $(mount | grep "${target}${p}"4) ]] && umount -qlf /dev/"${target}${p}"4
	[[ $(swapon | grep "${target}${p}"1) ]] && swapoff /dev/"${target}${p}"1
	[[ $(swapon | grep "${target}${p}"2) ]] && swapoff /dev/"${target}${p}"2
	[[ $(swapon | grep "${target}${p}"3) ]] && swapoff /dev/"${target}${p}"3
	[[ $(swapon | grep "${target}${p}"4) ]] && swapoff /dev/"${target}${p}"4

	return 0
}

function _prepWipe(){
	_msg "Wiping target"

	wipefs --all "/dev/$target"* 1> /dev/null
	dd if=/dev/zero of="/dev/$target" bs=1M count=1024

	return 0
}

function _prepPartBIOS() {
	_msg 'Partitioning (BIOS) (SWAP; /; /boot; /home)'

	(
		echo 'o'
		echo 'n'; echo 'p'; echo; echo; echo "$grubSize"; echo 'a';
		echo 'n'; echo 'p'; echo; echo; echo "$swapSize"
		echo 't'; echo '2'; echo 'swap'
		echo 'n'; echo 'p'; echo; echo; echo "$systemSize"
		echo 'n'; echo 'p'; echo; echo
		echo 'w';
	) | fdisk "/dev/$target" 1> /dev/null

	return 0
}

function _prepFormat() {
	_msg "Formating"

	[ "$targetType" == "nvme" ] && p="p" || p=""

	mkfs.ext4 -q /dev/"${target}${p}"4
	mkfs.ext4 -q /dev/"${target}${p}"3
	mkfs.ext4 -q /dev/"${target}${p}"1
	mkswap -q /dev/"${target}${p}"2

	return 0
}

function _prepFormatKeepHome() {
	_msg "Formating - Keeping /home"

	[ "$targetType" == "nvme" ] && p="p" || p=""

	mkfs.ext4 -q /dev/"${target}${p}"3
	mkfs.ext4 -q /dev/"${target}${p}"1
	mkswap -q /dev/"${target}${p}"2

	return 0
}

function _prepMount() {
	_msg 'Mounting'

	[ "$targetType" == "nvme" ] && p="p" || p=""

	mount /dev/"${target}${p}"3 /mnt
	mkdir -p /mnt/{boot,home}
	mount /dev/"${target}${p}"4 /mnt/home
	mount /dev/"${target}${p}"1 /mnt/boot
	swapon /dev/"${target}${p}"2

	return 0
}

function _prepCleanHomeDots () {
	_msgInfo "###   Cleaning User Dots   ###"

	[ -d /mnt/home/lost+found ] && _msg "Removing: lost+found" && rm -rf /mnt/home/lost+found

	for userInHome in /mnt/home/*; do
		userHome=$(basename $userInHome)
		_msg "$userHome"
		if [[ "$userHome" != "shared" ]]; then
			rm -rf /mnt/home/"$userHome"/.*
			[ -d "/mnt/home/${userInHome}/Desktop" ] && rm -f /mnt/home/"$userHome"/Desktop/*.desktop
		fi
	done

	return 0
}

function _prepTarget() {
	_msgInfo "###   Preparing Target   ###"

	_prepHardUmount

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
	_msg "Pacstraping with $pacmanConf"

	pacman -Scc --noconfirm 1> /dev/null
	pacman -Syy --config "$pacmanConf" 1> /dev/null
	pacstrap -KMC "$pacmanConf" /mnt base linux linux-firmware mkinitcpio grub 1> /dev/null

	return 0
}

function _instFiles() {
	_msg "Installing gChroot Script"

	install -Dm 700 -t /mnt/gChroot gChroot.sh
	install -Dm 644 -t /mnt/gChroot/utils utils/gMsg.sh

	echo "#!/bin/bash
		target=\"${target}\"
		targetType=\"${targetType}\"
		profile=\"${profile}\"
		cpuType=\"${cpuType}\"
		gRootPasswd=\"${gRootPasswd}\"
		gAdminPasswd=\"${gAdminPasswd}\"
		gRadioPasswd=\"${gRadioPasswd}\"
		gGremioPasswd=\"${gGremioPasswd}\"
		keepHome=$keepHome
		localDevInstall=$localDevInstall" > /mnt/gChroot/utils/chrConfig.sh

	_msg "Installing Config Files"

	install -Dm 644 -t /mnt/etc root/etc/hostname
	install -Dm 644 -t /mnt/etc root/etc/hosts

	install -Dm 644 -t /mnt/etc root/etc/locale.conf
	chattr +i /mnt/etc/locale.conf

	install -Dm 644 -t /mnt/etc root/etc/locale.gen
	chattr +i /mnt/etc/locale.gen

	if [ $localDevInstall -eq 0 ]; then
		install -Dm 644 -t /mnt/etc utils/pacman_local.conf
		mv -f /mnt/etc/pacman_local.conf /mnt/etc/pacman.conf
	else
		_msgAlert "Dev Build pacman.conf"
		install -Dm 644 -t /mnt/etc ../utils/pacman_dev.conf
		mv -f /mnt/etc/pacman_dev.conf /mnt/etc/pacman.conf
		chattr +i /mnt/etc/pacman.conf
		install -Dm 644 -t /mnt/etc utils/pacman_local.conf
	fi

	return 0
}

function _instFstab() {
	_msg "Generating fstab"

	genfstab -U /mnt >> /mnt/etc/fstab
	sed -i '/^\/swapfile/d' /mnt/etc/fstab
	[[ "$targetType" == "ssd" || "$targetType" == "nvme" ]] && sed -i "s/relatime/noatime/g" /mnt/etc/fstab
	chattr +i /mnt/etc/fstab

	return 0
}

function _instChroot() {
	_msgOk "###   CHROOT   ###"

	arch-chroot /mnt /gChroot/gChroot.sh

	_msg "Cleaning installer files"
	rm -r /mnt/gChroot

	return 0
}

function _installGoylin() {
	_msgInfo "###   Instaling Goylin   ###"

	_instPacstrap
	_instFiles
	_instFstab
	_instChroot

	return 0
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && exit

_msgWelcome
_setup

[ $localDevInstall -eq 0 ] && _bootstrap
_prepTarget
_installGoylin
_prepUmount
_msgDone

exit 0
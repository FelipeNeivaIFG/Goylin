#!/bin/bash

set -ue # Unbound Variables || Error == exit

cd "$(dirname $(readlink -f "$0"))" || exit 1

####################################################################################################
###                                        Source                                                ###
####################################################################################################

. utils/msg.sh
. utils/secrets.sh
. utils/installConf.sh

####################################################################################################
###                                        Help                                                  ###
####################################################################################################

function _help() {
	_msgInfo "Goylin installer flags:"
	_msgOpt "-d : Use default configuration. (utils/installConf.sh)"
	_msgOpt "-l : Local repository development installation."

	echo; exit 0
}

####################################################################################################
###                                        Flags                                                 ###
####################################################################################################

while getopts "dl" opt; do
	case $opt in
		d) useDefaultConf=1;;
		l) devInstall=1; pacmanConf="../utils/pacman_dev.conf";;
		*) _help;;
	esac
done

####################################################################################################
###                                        Setup                                                 ###
####################################################################################################

function _setTarget() {
	[ $devInstall -eq 1 ] && local protectTarget=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /))

	_msg "Available Target devices:"
	if [ $devInstall -eq 1 ]; then
		lsblk -o NAME,SIZE,TYPE | awk '$3 == "disk"' | grep -v "$protectTarget"
	else
		lsblk -o NAME,SIZE,TYPE | awk '$3 == "disk"'
	fi

	_msgOpt "Target name? ( eg. sdx )"
	read -p "?: " -e target

	[ "$target" == "" ] && _msgAlert "Target Device Required!" && exit 1
	[ ! -b "/dev/$target" ] && _msgAlert "Null device!" && exit 1
	[ $devInstall -eq 1 ] && [ "$target" == "$protectTarget" ] && _msgAlert "WTF!? This device belongs to current system!" && exit 1

	echo
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

	echo
}

function _setCPU() {
	_msg "CPU:"
	_msgOpt "1) AMD"
	_msgOpt "2) Intel"
	_msgOpt "*) Intel w/Vulkan (IvyBridge)"
	read -p '?: ' -e optCpuType

	case $optCpuType in
		1) cpuType="amd";;
		2) cpuType="intel";;
		*) cpuType="intelNoVulkan";;
	esac

	echo
}

function _setKeepHome() {
	_msg "Keep /home and Upgrade?"
	_msgOpt "(y/N)"
	read -p "?: " -e optKeepHome

	[[ "$optKeepHome" == "y" || "$optKeepHome" == "Y" ]] && keepHome=1 

	echo
}

function _setProfile() {
	_msg "Profile:"
	_msgOpt "1) Administrative"
	_msgOpt "2) Library"
	_msgOpt "3) Cinema"
	_msgOpt "4) Agro"
	_msgOpt "5) Art"
	_msgOpt "6) Computing"
	_msgOpt "7) Teach"
	_msgOpt "8) Radio"
	_msgOpt "*) Base"
	read -p '?: ' -e optProfile

	case $optProfile in
		1) profile="adm";;
		2) profile="lib";;
		3) profile="cine";;
		4) profile="agro";;
		5) profile="art";;
		6) profile="comp";;
		7) profile="teach";;
		8) profile="radio";;
		*) profile="base";;
	esac

	echo
}

function _setConfirm() {
	_msg "Settings:"
	_msgOpt "Target: $target"
	_msgOpt "Type: $targetType"
	_msgOpt "KeepHome: $keepHome"
	_msgOpt "CPU: $cpuType"
	_msgOpt "Profile: $profile"

	echo; _msgAlert "Confirm (y/N)"
	read -p "?: " -e setConfirm
	[ ! "$setConfirm" == "y" ] && _msgAlert "Aborting" && exit 1

	echo
}

function _initSetup() {
	_msgInfo "###   Install settings  ###"

	_setTarget

	if [ "$useDefaultConf" -eq 0 ]; then
		_setTargetType
		_setCPU
		_setKeepHome
	fi

	_setProfile
	_setConfirm
}

####################################################################################################
###                               Bootstrap Installer                                            ###
####################################################################################################

function _bootstrap() {
	_msgInfo "###   Bootstraping Installer  ###"

	_msg "Time Sync"
	timedatectl set-ntp true
	hwclock --systohc

	_msg "Pacman Sync"
	pacman -Syy --config "$pacmanConf" 1> /dev/null
	pacman-key --init --config "$pacmanConf" 1> /dev/null
	pacman-key --populate --config "$pacmanConf" 1> /dev/null
}

####################################################################################################
###                                       Target                                                 ###
####################################################################################################

function _prepUmount() {
	_msg "Unmounting"

	sync

	[[ $(mount | grep /mnt) ]] && umount -qlfR /mnt
	[[ $(mount | grep "${target}${p}"1) ]] && umount -qlf /dev/"${target}${p}"1
	[[ $(mount | grep "${target}${p}"2) ]] && umount -qlf /dev/"${target}${p}"2
	[[ $(mount | grep "${target}${p}"3) ]] && umount -qlf /dev/"${target}${p}"3
	[[ $(mount | grep "${target}${p}"4) ]] && umount -qlf /dev/"${target}${p}"4

	return 0
}

function _prepWipe(){
	_msg "Wiping target"

	wipefs --all "/dev/$target"* 1> /dev/null
	dd if=/dev/zero of="/dev/$target" bs=1M count=1024 1> /dev/null
}

function _prepPart() {
	_msg 'Partitioning (/; /boot; /home)'

	(
		echo 'o'
		echo 'n'; echo 'p'; echo; echo; echo "+${grubSize}"; echo 'a';
		echo 'n'; echo 'p'; echo; echo; echo "+${systemSize}"
		echo 'n'; echo 'p'; echo; echo; echo;
		echo 'w';
	) | fdisk "/dev/$target" 1> /dev/null
}

function _prepFormat() {
	_msg "Formating (ext4)"

	mkfs.ext4 -qF /dev/"${target}${p}"3
	mkfs.ext4 -qF /dev/"${target}${p}"2
	mkfs.ext4 -qF /dev/"${target}${p}"1
}

function _prepFormatKeepHome() {
	_msg "Formating - Keeping /home"

	mkfs.ext4 -qF /dev/"${target}${p}"2
	mkfs.ext4 -qF /dev/"${target}${p}"1
}

function _prepMount() {
	_msg 'Mounting'

	mount /dev/"${target}${p}"2 /mnt
	mkdir -p /mnt/{boot,home}
	mount /dev/"${target}${p}"3 /mnt/home
	mount /dev/"${target}${p}"1 /mnt/boot
}

function _prepCleanHomeDots () {
	_msgInfo "###   Cleaning User Dots   ###"

	[ -d /mnt/home/lost+found ] && _msg "Removing: /home/lost+found" && rm -rf /mnt/home/lost+found
	[ -d /mnt/home/shared ] && _msg "Removing: /home/shared" && rm -rf /mnt/home/shared

	for userInHome in /mnt/home/*; do
		userHome=$(basename $userInHome)
		if [[ "$userHome" != "shared" ]]; then
			_msg "Cleaning: $userHome"
			rm -rf /mnt/home/"$userHome"/.*
			[ -d "/mnt/home/${userInHome}/Desktop" ] && rm -f /mnt/home/"$userHome"/Desktop/*.desktop
		fi
	done
}

function _prepTarget() {
	_msgInfo "###   Preparing Target   ###"

	[ "$targetType" == "nvme" ] && p="p" || p=""

	_prepUmount

	if [ $keepHome -eq 1 ]; then
		_prepFormatKeepHome
		_prepCleanHomeDots
		_prepMount
	else
		_prepWipe
		_prepPart
		_prepFormat
		_prepMount
	fi
}

####################################################################################################
###                                  System Install                                              ###
####################################################################################################

function _instPacstrap() {
	_msg "Pacstraping with $pacmanConf"; echo

	pacman -Scc --noconfirm 1> /dev/null
	pacman -Syy --config "$pacmanConf" 1> /dev/null
	pacstrap -KMC "$pacmanConf" /mnt base linux-zen linux-firmware mkinitcpio grub

	echo
}

function _instFiles() {
	_msg "Installing gChroot Script"

	install -Dm 700 -t /mnt/gChroot gChroot.sh
	install -Dm 644 -t /mnt/gChroot/utils utils/msg.sh

	echo "#!/bin/bash
		target=\"${target}\"
		targetType=\"${targetType}\"
		profile=\"${profile}\"
		cpuType=\"${cpuType}\"
		gRootPasswd=\"${gRootPasswd}\"
		gAdminPasswd=\"${gAdminPasswd}\"
		keepHome=$keepHome
		devInstall=${devInstall}" > /mnt/gChroot/utils/chrConf.sh

	_msg "Installing Config Files"

	install -Dm 644 -t /mnt/etc/ etc/hostname
	chattr +i /mnt/etc/hostname
	install -Dm 644 -t /mnt/etc/ etc/hosts
	chattr +i /mnt/etc/hosts
	install -Dm 644 -t /mnt/etc/ etc/locale.conf
	chattr +i /mnt/etc/locale.conf
	install -Dm 644 -t /mnt/etc/ etc/locale.gen
	chattr +i /mnt/etc/locale.gen
	install -Dm 644 -t /mnt/etc/systemd/ /etc/systemd/timesyncd.conf
	chattr +i /mnt/etc/systemd/timesyncd.conf
	install -Dm 644 -t /mnt/etc/sysctl.d/ etc/sysctl.d/99-swapiness.conf

	if [ $devInstall -eq 0 ]; then
		install -Dm 644 -t /mnt/etc utils/pacman_goylin.conf
		mv -f /mnt/etc/pacman_goylin.conf /mnt/etc/pacman.conf
	else
		_msgAlert "Dev Build pacman.conf"
		install -Dm 644 -t /mnt/etc utils/pacman_goylin.conf
	
		install -Dm 644 -t /mnt/etc ../utils/pacman_dev.conf
		mv -f /mnt/etc/pacman_dev.conf /mnt/etc/pacman.conf
		chattr +i /mnt/etc/pacman.conf
	fi
}

function _instFstab() {
	_msg "Generating fstab"

	genfstab -U /mnt >> /mnt/etc/fstab
	[[ "$targetType" == "ssd" || "$targetType" == "nvme" ]] && sed -i "s/relatime/noatime/g" /mnt/etc/fstab

	_msg "Generating swapfile"

	# Prevent developer SWAP bleeding to installed system.
	sed -i "/\sswap\s/d" /mnt/etc/fstab

	mkswap -U clear -s $swapSize -F /mnt/swapfile 1> /dev/null
	printf "# /swapfile\n/swapfile	swap	swap	defaults,noatime 0 0" | tee -a /mnt/etc/fstab 1> /dev/null

	chattr +i /mnt/etc/fstab
}

function _instChroot() {
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

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && exit 0

_msgWelcome
_initSetup
[ $devInstall -eq 0 ] && _bootstrap
_prepTarget
_installGoylin
_prepUmount
_msgDone

exit 0
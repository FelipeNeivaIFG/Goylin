#!/bin/bash

set -ue

####################################################################################################
###                                        Source                                                ###
####################################################################################################

. gChroot/utils/gMsg.sh
. gChroot/utils/chrConfig.sh

####################################################################################################
###                                        Settings                                              ###
####################################################################################################

function _configSys() {
	_msgInfo "###  Base Config  ###"

	_msg "Timezone"
	ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
	locale-gen

	[[ "$targetType" == "ssd" || "$targetType" == "nvme" ]] && _msg "SSD fstrim" && systemctl enable fstrim.timer

	_msg "Bootstrap Pacman"
	pacman --disable-download-timeout --noconfirm -Syu 1> /dev/null

	return 0
}

function _configUsers() {
	_msgInfo "###   Users & groups   ###"

	_msg "root"
	echo -e "${gRootPasswd}\n${gRootPasswd}" | passwd root

	_msg "admin"
	useradd -mG wheel admin
	echo -e "${gAdminPasswd}\n${gAdminPasswd}" | passwd admin

	_msg "guest"
	groupadd -r nopasswdlogin
	useradd -mG nopasswdlogin guest
	chfn -f "Público" guest

	case $profile in
		"radio")
			_msg "radiovozes"
			useradd -m radiovozzes
			echo -e "$gRadioPasswd\n$gRadioPasswd" | passwd radiovozzes
			chfn -f "Radio Vozzes" radiovozzes
		;;
		"gremio")
			_msg "gremio"
			useradd -m gremio
			echo -e "${gGremioPasswd}\n${gGremioPasswd}" | passwd gremio
			chfn -f "Grêmio" gremio
		;;
		*);;
	esac

	_msg "Shared Home"
	mkdir -p /home/shared/

	return 0
}

function _configCPIO() {
	_msgInfo "###   mkinitcpio   ###"

	mkinitcpio -P 1> /dev/null

	return 0
}

function _configGRUB() {
	_msgInfo "###   GRUB   ###"

	grub-install --target=i386-pc /dev/${target} 1> /dev/null
	grub-mkconfig -o /boot/grub/grub.cfg 1> /dev/null

	return 0
}

function _finishUp() {
	_msgInfo "###   Finishing Chroot   ###"
	pacman -Scc --noconfirm 1> /dev/null

	if [ $localDevInstall -eq 1 ]; then
		_msgAlert "Dev Build Settings"

		systemctl disable goylin.service
		chattr -i /etc/hostname
		chattr -i /etc/hosts
		sed -i "s/GOITESTE/GOI-DEV-BUILD/g" /etc/hostname
		sed -i "s/GOITESTE/GOI-DEV-BUILD/g" /etc/hosts
		chattr +i /etc/hostname
		chattr +i /etc/hosts
	fi

	return 0
}

####################################################################################################
###                                      PKGs                                                    ###
####################################################################################################

function _install_PKG() {
	pacman --disable-download-timeout --noconfirm --needed --overwrite "*" -S $1 1> /dev/null
}

function _pkgCore() {
	_msgInfo "###   Core PKGs   ###"

	_msg "Core"; _install_PKG g-core

	case $cpuType in
		"intel") _msg "Intel"; _install_PKG g-intel;;
		"amd") _msg "AMD"; _install_PKG g-amd;;
	esac

	_msg "AD"; _install_PKG g-ad
	_msg "Audio"; _install_PKG g-audio

	_msg "Greeter"; _install_PKG g-greeter
	_msg "Desktop"; _install_PKG g-desktop
	_msg "File Manager"; _install_PKG g-fileman

	_msg "Plasma"; _install_PKG g-plasma
	_msg "i3"; _install_PKG g-i3

	_msg "Backgrounds"; _install_PKG g-backgrounds
	_msg "Fonts"; _install_PKG g-fonts

	_msg "App: Base"; _install_PKG gapp-base
	_msg "App: Wine"; _install_PKG gapp-wine
	_msg "Profile: Base"; _install_PKG gp-base

	# Use to apply quick dirty fixes if needed =)
	_msg "Patches"; _install_PKG g-patch
}

function _pAdm() {
	_msgInfo "###   Profile: Administrative   ###"

	_msg "Printer"; _install_PKG g-printer
	_msg "App: Administrative"; _install_PKG gapp-adm

	_msg "Profile"; _install_PKG gp-adm
}

function _pCinema() {
	_msgInfo "###   Profile: Cinema   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Write"; _install_PKG gapp-write
	_msg "App: Image"; _install_PKG gapp-image
	_msg "App: Animation"; _install_PKG gapp-anim
	_msg "App: VFX"; _install_PKG gapp-vfx
	_msg "App: Video"; _install_PKG gapp-video

	# Not related to cinema, but...
	_msg "App: Code"; _install_PKG gapp-code
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Game Dev"; _install_PKG gapp-gameDev

	# Should be for Library only, but...
	_msg "App: Educational"; _install_PKG gapp-edu

	# For Game classes
	_msg "App: Game Emulation"; _install_PKG gapp-gameEmu

	_msg "Profile"; _install_PKG gp-cinema
}

function _pAgro() {
	_msgInfo "###   Profile: Agro   ###"

	_msg "App: Cad"; _install_PKG gapp-cad
	_msg "App: Geo"; _install_PKG gapp-geo

	_msg "Profile"; _install_PKG gp-agro
}

function _pRadio() {
	_msgInfo "###   Profile: Radio   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Image"; _install_PKG gapp-image
	_msg "App: Video"; _install_PKG gapp-video
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "Printer"; _install_PKG g-printer
	_msg "App: Administrative"; _install_PKG gapp-adm

	_msg "Profile"; _install_PKG gp-radio
}

function _pGremio() {
	_msgInfo "###   Profile: Gremio   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Image"; _install_PKG gapp-image
	_msg "App: Write"; _install_PKG gapp-write
	_msg "App: Animation"; _install_PKG gapp-anim
	_msg "App: VFX"; _install_PKG gapp-vfx
	_msg "App: Video"; _install_PKG gapp-video
	_msg "App: Code"; _install_PKG gapp-code
	_msg "App: Game Dev"; _install_PKG gapp-gameDev
	_msg "App: Educational"; _install_PKG gapp-edu
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Game"; _install_PKG gapp-game
	_msg "App: Game Emulation"; _install_PKG gapp-gameEmu

	_msg "Profile"; _install_PKG gp-gremio
}

function _pLibrary() {
	_msgInfo "###   Profile: Library   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Image"; _install_PKG gapp-image
	_msg "App: Write"; _install_PKG gapp-write
	_msg "App: Animation"; _install_PKG gapp-anim
	_msg "App: VFX"; _install_PKG gapp-vfx
	_msg "App: Video"; _install_PKG gapp-video
	_msg "App: Cad"; _install_PKG gapp-cad
	_msg "App: Geo"; _install_PKG gapp-geo
	_msg "App: Code"; _install_PKG gapp-code
	_msg "App: Game Dev"; _install_PKG gapp-gameDev
	_msg "App: Educational"; _install_PKG gapp-edu
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Game"; _install_PKG gapp-game
	_msg "App: Game Emulation"; _install_PKG gapp-gameEmu

	_msg "Profile"; _install_PKG gp-lib
}

function _pkgProfile() {
	case $profile in
		"adm") _pAdm;;
		"cinema") _pCinema;;
		"agro") _pAgro;;
		"radio") _pRadio;;
		"gremio") _pGremio;;
		"library") _pLibrary;;
		*);;
	esac
}

####################################################################################################
###                                     GCHROOT INIT                                             ###
####################################################################################################

_configSys
_pkgCore
_pkgProfile
_configUsers
_configCPIO
_configGRUB
_finishUp

_msgOk "###   Exiting CHROOT   ###"

sync
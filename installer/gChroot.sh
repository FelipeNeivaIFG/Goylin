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
	pacman --disable-download-timeout --noconfirm -Syu # 1> /dev/null

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

	mkinitcpio -P # 1> /dev/null

	return 0
}

function _configGRUB() {
	_msgInfo "###   GRUB   ###"

	grub-install --target=i386-pc /dev/${target} # 1> /dev/null
	grub-mkconfig -o /boot/grub/grub.cfg # 1> /dev/null

	return 0
}

function _finishUp() {
	_msgInfo "###   Finishing Chroot   ###"
	pacman -Scc --noconfirm

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
	pacman --disable-download-timeout --noconfirm --needed --overwrite "*" -S $1 # 1> /dev/null
}

function _pkgCore() {
	# ~16GB
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

	_msg "i3"; _install_PKG g-i3
	# _msg "Budgie"; _install_PKG g-budgie
	# _msg "Gnome"; _install_PKG g-gnome
	_msg "Plasma"; _install_PKG g-plasma

	_msg "Backgrounds"; _install_PKG g-backgrounds
	_msg "Fonts"; _install_PKG g-fonts

	# Use to apply quick dirty fixes if needed =)
	_msg "Patches"; _install_PKG g-patch

	_msgInfo "###   Profile: Base   ###"

	_msg "App: Base"; _install_PKG gapp-base
	_msg "App: Wine"; _install_PKG gapp-wine
	_msg "Profile: Base"; _install_PKG gp-base
}

function _pAdm() {
	# ~19GB
	_msgInfo "###   Profile: Administrative   ###"

	_msg "Printer"; _install_PKG g-printer
	_msg "App: Administrative"; _install_PKG gapp-adm

	_msg "Profile"; _install_PKG gp-adm
}

function _pCinema() {
	# ~25GB
	_msgInfo "###   Profile: Cinema   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Write"; _install_PKG gapp-write
	_msg "App: Image"; _install_PKG gapp-image
	_msg "App: Animation"; _install_PKG gapp-anim
	_msg "App: VFX"; _install_PKG gapp-vfx
	_msg "App: Video"; _install_PKG gapp-video

	# For Game classes
	_msg "App: Game Emulation"; _install_PKG gapp-gameEmu
	_msg "App: Game Dev"; _install_PKG gapp-gameDev

	# 4Fun
	_msg "App: CLI"; _install_PKG gapp-cli

	_msg "Profile"; _install_PKG gp-cinema
	_msg "DarkMode"; _install_PKG gp-dark
}

function _pAgro() {
	# ~20GB
	_msgInfo "###   Profile: Agro   ###"

	_msg "App: Cad"; _install_PKG gapp-cad
	_msg "App: Geo"; _install_PKG gapp-geo

	_msg "Profile"; _install_PKG gp-agro
}

function _pRadio() {
	# ~24GB
	_msgInfo "###   Profile: Radio   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Image"; _install_PKG gapp-image
	_msg "App: Video"; _install_PKG gapp-video
	_msg "Printer"; _install_PKG g-printer

	_msg "Profile"; _install_PKG gp-radio
	_msg "DarkMode"; _install_PKG gp-dark
}

function _pGremio() {
	# ~31GB
	_msgInfo "###   Profile: Gremio   ###"

	_msg "App: Educational"; _install_PKG gapp-edu
	_msg "App: Game"; _install_PKG gapp-game
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Game Emulation"; _install_PKG gapp-gameEmu

	_msg "Profile"; _install_PKG gp-gremio
}

function _pLibrary() {
	# ~31GB
	_msgInfo "###   Profile: Library   ###"

	_msg "App: Educational"; _install_PKG gapp-edu
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Game"; _install_PKG gapp-game
	_msg "App: Game Emulation"; _install_PKG gapp-gameEmu

	_msg "Profile"; _install_PKG gp-lib
}

function _pInf() {
	# ~30GB
	_msgInfo "###   Profile: Inf   ###"

	_msg "App: Code"; _install_PKG gapp-code
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Game Dev"; _install_PKG gapp-gameDev

	_msg "Profile"; _install_PKG gp-inf
}

function _pkgProfile() {
	case $profile in
		"adm") _pAdm;;
		"cinema") _pCinema;;
		"agro") _pAgro;;
		"radio") _pRadio;;
		"gremio") _pGremio;;
		"library") _pLibrary;;
		"inf") _pInf;;
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
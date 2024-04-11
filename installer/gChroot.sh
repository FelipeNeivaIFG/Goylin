#!/bin/bash

set -u # Unbound Variables == exit
set -e # Error == exit
set -o pipefail # Error on pipe end == exit

####################################################################################################
###                                        Source                                                ###
####################################################################################################

source gChroot/utils/gMsg.sh
source gChroot/utils/chrConfig.sh

####################################################################################################
###                                        Settings                                              ###
####################################################################################################

function _configSys() {
	_msgInfo "###  Base Config  ###"

	_msg "Timezone"
	ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
	locale-gen

	[ "$targetType" == "ssd" ] && _msg "SSD fstrim" && systemctl enable fstrim.timer

	_msg "Bootstrap Pacman"
	pacman --noconfirm -Syyu 1> /dev/null
}

function _configUsers() {
	_msgInfo "###   Users & groups   ###"

	_msg "Root"
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
		*) ;;
	esac
}

function _configCPIO() {
	_msgInfo "###   mkinitcpio   ###"

	pacman --noconfirm --needed -S mkinitcpio 1> /dev/null
	mkinitcpio -P 1> /dev/null
}

function _configGRUB() {
	_msgInfo "###   GRUB   ###"

	pacman --noconfirm --needed -S grub 1> /dev/null
	grub-install --target=i386-pc /dev/${target} 1> /dev/null
	grub-mkconfig -o /boot/grub/grub.cfg 1> /dev/null
}

####################################################################################################
###                                      Base PKGs                                               ###
####################################################################################################

function _pkgCore() {
	_msgInfo "###   Core PKGs   ###"

	case $cpuType in
		"intel") _msg "Intel"; pacman --noconfirm --needed --overwrite "*" -S g-intel 1> dev/null ;;
		"amd") _msg "AMD"; pacman --noconfirm --needed --overwrite "*" -S g-amd 1> /dev/null ;;
	esac

	_msg "Core"
	pacman --noconfirm --needed --overwrite "*" -S g-core 1> /dev/null
	_msg "AD"
	pacman --noconfirm --needed --overwrite "*" -S g-ad 1> /dev/null

	_msg "Desktop"
	pacman --noconfirm --needed --overwrite "*" -S g-desktop 1> /dev/null
	_msg "Backgrounds"
	pacman --noconfirm --needed --overwrite "*" -S g-backgrounds 1> /dev/null
	_msg "Fonts"
	pacman --noconfirm --needed --overwrite "*" -S g-fonts 1> /dev/null

	_msg "Plasma"
	pacman --noconfirm --needed --overwrite "*" -S g-plasma 1> /dev/null
	#   _msg 'i3'
	#   pacman --noconfirm --needed --overwrite "*" -S g-i3 1> /dev/null
	#   _msg 'hyprland'
	#   pacman --noconfirm --needed --overwrite "*" -S g-hyprland 1> /dev/null
	#   _msg 'gnome'
	#   pacman --noconfirm --needed --overwrite "*" -S g-gnome 1> /dev/nullW

	_msg "App: Base"
	pacman --noconfirm --needed --overwrite "*" -S gapp-base 1> /dev/null
	_msg "Profile: Base"
	pacman --noconfirm --needed --overwrite "*" -S gp-base 1> /dev/null
}

####################################################################################################
###                                    Profiles                                                  ###
####################################################################################################

function _pAdm() {
	_msgInfo "###   Profile: Administrative   ###"

	_msg "Profile"
	pacman --noconfirm --needed --overwrite "*" -S gp-adm 1> /dev/null

	sed -i "s/core/Administrative/g" /usr/lib/os-release
}

function _pCinema() {
	_msgInfo "###   Profile: Cinema   ###"

	_msg "App: VFX"
	pacman --noconfirm --needed --overwrite "*" -S gapp-vfx 1> /dev/null
	_msg "App: Audio"
	pacman --noconfirm --needed --overwrite "*" -S gapp-audio 1> /dev/null
	_msg "App: Image"
	pacman --noconfirm --needed --overwrite "*" -S gapp-image 1> /dev/null
	_msg "App: Video"
	pacman --noconfirm --needed --overwrite "*" -S gapp-video 1> /dev/null
	_msg "App: Write"
	pacman --noconfirm --needed --overwrite "*" -S gapp-write 1> /dev/null
	_msg "App: Code"
	pacman --noconfirm --needed --overwrite "*" -S gapp-code 1> /dev/null
	_msg "App: GameDev"
	pacman --noconfirm --needed --overwrite "*" -S gapp-gameDev 1> /dev/null

	_msg "Profile"
	pacman --noconfirm --needed --overwrite "*" -S gp-cinema 1> /dev/null

	sed -i "s/core/cinema/g" /usr/lib/os-release
	sed -i 's/goylin.desktop/goylindark.desktop/g' /etc/xdg/kdeglobals
}

function _pGeo() {
	_msgInfo "###   Profile: Geo   ###"

	_msg "App: Geo"
	pacman --noconfirm --needed --overwrite "*" -S gapp-geo 1> /dev/null
	_msg "App: Cad"
	pacman --noconfirm --needed --overwrite "*" -S gapp-cad 1> /dev/null

	_msg "Profile"
	pacman --noconfirm --needed --overwrite "*" -S gp-geo 1> /dev/null

	sed -i "s/core/geotecnologia/g" /usr/lib/os-release
}

function _pRadio() {
	_msgInfo "###   Profile: Radio   ###"

	_msg "App: Audio"
	pacman --noconfirm --needed --overwrite "*" -S gapp-audio 1> /dev/null
	_msg "App: Video"
	pacman --noconfirm --needed --overwrite "*" -S gapp-video 1> /dev/null
	_msg "App: Image"
	pacman --noconfirm --needed --overwrite "*" -S gapp-image 1> /dev/null

	_msg "Profile"
	pacman --noconfirm --needed --overwrite "*" -S gp-radio 1> /dev/null

	sed -i "s/core/radio/g" /usr/lib/os-release
	sed -i 's/goylin.desktop/goylindark.desktop/g' /etc/xdg/kdeglobals
}

function _pGremio() {
	_msgInfo "###   Profile: Gremio   ###"

	_msg "App: Geo"
	pacman --noconfirm --needed --overwrite "*" -S gapp-geo 1> /dev/null
	_msg "App: Code"
	pacman --noconfirm --needed --overwrite "*" -S gapp-code 1> /dev/null
	_msg "App: Cad"
	pacman --noconfirm --needed --overwrite "*" -S gapp-cad 1> /dev/null
	_msg "App: VFX"
	pacman --noconfirm --needed --overwrite "*" -S gapp-vfx 1> /dev/null
	_msg "App: Audio"
	pacman --noconfirm --needed --overwrite "*" -S gapp-audio 1> /dev/null
	_msg "App: Video"
	pacman --noconfirm --needed --overwrite "*" -S gapp-video 1> /dev/null
	_msg "App: Image"
	pacman --noconfirm --needed --overwrite "*" -S gapp-image 1> /dev/null
	_msg "App: Game"
	pacman --noconfirm --needed --overwrite "*" -S gapp-game 1> /dev/null
	_msg "App: Write"
	pacman --noconfirm --needed --overwrite "*" -S gapp-write 1> /dev/null
	_msg "App: GameDev"
	pacman --noconfirm --needed --overwrite "*" -S gapp-gameDev 1> /dev/null
	_msg "App: Educational"
	pacman --noconfirm --needed --overwrite "*" -S gapp-edu 1> /dev/null

	_msg "Profile"
	pacman --noconfirm --needed --overwrite "*" -S gp-gremio 1> /dev/null

	sed -i "s/core/gremio/g" /usr/lib/os-release
}

function _pLibrary() {
	_msgInfo "###   Profile: Library   ###"

	_msg "App: Geo"
	pacman --noconfirm --needed --overwrite "*" -S gapp-geo 1> /dev/null
	_msg "App: Code"
	pacman --noconfirm --needed --overwrite "*" -S gapp-code 1> /dev/null
	_msg "App: Cad"
	pacman --noconfirm --needed --overwrite "*" -S gapp-cad 1> /dev/null
	_msg "App: VFX"
	pacman --noconfirm --needed --overwrite "*" -S gapp-vfx 1> /dev/null
	_msg "App: Audio"
	pacman --noconfirm --needed --overwrite "*" -S gapp-audio 1> /dev/null
	_msg "App: Video"
	pacman --noconfirm --needed --overwrite "*" -S gapp-video 1> /dev/null
	_msg "App: Image"
	pacman --noconfirm --needed --overwrite "*" -S gapp-image 1> /dev/null
	_msg "App: Game"
	pacman --noconfirm --needed --overwrite "*" -S gapp-game 1> /dev/null
	_msg "App: Write"
	pacman --noconfirm --needed --overwrite "*" -S gapp-write 1> /dev/null
	_msg "App: GameDev"
	pacman --noconfirm --needed --overwrite "*" -S gapp-gameDev 1> /dev/null
	_msg "App: Educational"
	pacman --noconfirm --needed --overwrite "*" -S gapp-edu 1> /dev/null

	sed -i "s/core/library/g" /usr/lib/os-release
}

function _pLaptop() {
	_msgInfo "###   Profile: Laptop   ###"

	_msg "Laptop"
	pacman --noconfirm --needed --overwrite "*" -S g-laptop 1> /dev/null
	_msg "App: Educational"
	pacman --noconfirm --needed --overwrite "*" -S gapp-edu 1> /dev/null
	
	_msg "Profile: adm"
	pacman --noconfirm --needed --overwrite "*" -S gp-adm 1> /dev/null

	sed -i "s/core/laptop/g" /usr/lib/os-release
}

function _getProfile() {
	case $profile in
		"adm") _pAdm ;;
		"cine") _pCinema ;;
		"geo") _pGeo ;;
		"radio") _pRadio ;;
		"gremio") _pGremio ;;
		"lib") _pLibrary ;;
		"laptop") _pLaptop ;;
		*) ;;
	esac
}

####################################################################################################
###                                     GCHROOT INIT                                             ###
####################################################################################################

_configSys

_pkgCore
_getProfile
_configUsers
_configCPIO
_configGRUB

_msgOk "###   Exiting CHROOT   ###"
sync
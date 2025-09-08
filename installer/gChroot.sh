#!/bin/bash

set -ue # Unbound Variables || Error == exit 1

####################################################################################################
###                                        Source                                                ###
####################################################################################################

. gChroot/utils/msg.sh
. gChroot/utils/chrConf.sh

####################################################################################################
###                                        Settings                                              ###
####################################################################################################

function _configSys() {
	_msgInfo "###  System Config  ###"

	_msg "Timezone"
	ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
	locale-gen

	if [[ "$targetType" == "ssd" || "$targetType" == "nvme" ]]; then
		_msg "SSD fstrim"
		systemctl enable fstrim.timer

		# Avoids early swapping but prevents OOM
		_msg "vm.swappiness 20"
		sed -i 's/_SET_/20/g' /etc/sysctl.d/99-swapiness.conf

	else
		# Leverages caching to offset slow disk speeds
		_msg "vm.swappiness 60"
		sed -i 's/_SET_/60/g' /etc/sysctl.d/99-swapiness.conf

	fi
}

function _configUsers() {
	_msgInfo "###   Users & groups   ###"

	_msg "root"
	echo -e "${gRootPasswd}\n${gRootPasswd}" | passwd root 1> /dev/null

	_msg "admin"
	useradd -mG wheel admin
	echo -e "${gAdminPasswd}\n${gAdminPasswd}" | passwd admin 1> /dev/null

	_msg "guest"
	groupadd -r nopasswdlogin
	useradd -mG nopasswdlogin guest
	chfn -f "Público" guest 1> /dev/null

	mkdir -p /home/shared/
}

function _configBoot() {
	_msgInfo "###   Boot   ###"

	mkinitcpio -P 1> /dev/null

	grub-install --target=i386-pc /dev/${target} 1> /dev/null
	grub-mkconfig -o /boot/grub/grub.cfg 1> /dev/null
}

function _finishUp() {
	_msgInfo "###   Finishing Chroot   ###"

	pacman -Scc --noconfirm 1> /dev/null

	if [ $devInstall -eq 1 ]; then
		_msgAlert "Dev Build Settings"
		systemctl disable goylinDown.service 1> /dev/null
		chattr -i /etc/hostname
		chattr -i /etc/hosts
		sed -i "s/GOITESTE/GOI-DEV-BUILD/g" /etc/hostname
		sed -i "s/GOITESTE/GOI-DEV-BUILD/g" /etc/hosts
		chattr +i /etc/hostname
		chattr +i /etc/hosts
	fi
}

####################################################################################################
###                                      PKGs                                                    ###
####################################################################################################

function _pkgBootstrap() {
	_msgInfo "Bootstraping Pacman"

	pacman --disable-download-timeout --noconfirm -Syy 1> /dev/null
}

function _install_PKG() { pacman --disable-download-timeout --noconfirm --needed --overwrite "*" -S $1; echo; }

function _pkgCore() {
	_msgInfo "###   Core PKGs   ###"

	_msg "Core"; _install_PKG g-core

	case $cpuType in
		"intelNoVulkan") _msg "Intel (No Vulkan Support)"; _install_PKG g-intelIvy;;
		"intel") _msg "Intel"; _install_PKG g-intel;;
		"amd") _msg "AMD"; _install_PKG g-amd;;
	esac

	_msg "AD"; _install_PKG g-ad
	_msg "Audio"; _install_PKG g-audio
	_msg "Fonts"; _install_PKG g-fonts
	_msg "Greeter"; _install_PKG g-greeter
	_msg "Backgrounds"; _install_PKG g-backgrounds
	_msg "Desktop"; _install_PKG g-desktop
	_msg "Acessibility"; _install_PKG g-a11y

	_msg "Dolphin"; _install_PKG g-fileman
	_msg "Plasma"; _install_PKG g-plasma
	_msg "i3"; _install_PKG g-i3

	_msg "Patches"; _install_PKG g-patch
}

function _pBase() {
	_msgInfo "###   Profile: Base   ###"

	_msg "App: Wine"; _install_PKG gapp-wine
	_msg "App: Base"; _install_PKG gapp-base
	_msg "Profile: Base"; _install_PKG gp-base
}

function _pAdm() {
	_msgInfo "###   Profile: Administrative   ###"

	_msg "Printer"; _install_PKG g-printerGOI
	_msg "App: Administrative"; _install_PKG gapp-adm

	_msg "Profile"; _install_PKG gp-adm
}

function _pLibrary() {
	_msgInfo "###   Profile: Library   ###"

	_msg "App: Educational"; _install_PKG gapp-edu

	_msg "Profile"; _install_PKG gp-lib
}

function _pCinema() {
	_msgInfo "###   Profile: Cinema   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Write"; _install_PKG gapp-write
	_msg "App: Photo"; _install_PKG gapp-photo
	_msg "App: Design"; _install_PKG gapp-design
	_msg "App: Animation"; _install_PKG gapp-anim
	_msg "App: VFX"; _install_PKG gapp-vfx
	_msg "App: Video"; _install_PKG gapp-video
	_msg "App: CLI"; _install_PKG gapp-cli

	_msg "Profile"; _install_PKG gp-cinema
	_msg "DarkMode"; _install_PKG gp-dark
}

function _pAgro() {
	_msgInfo "###   Profile: Agro   ###"

	_msg "App: Cad"; _install_PKG gapp-cad
	_msg "App: Geo"; _install_PKG gapp-geo
	_msg "App: Data"; _install_PKG gapp-data
	_msg "App: Design"; _install_PKG gapp-design

	_msg "Profile"; _install_PKG gp-agro
}

function _pArt() {
	_msgInfo "###   Profile: Teach   ###"

	_msg "Printer"; _install_PKG g-printer
	_msg "App: Design"; _install_PKG gapp-design
	_msg "App: VFX"; _install_PKG gapp-vfx

	_msg "Profile"; _install_PKG gp-art
	_msg "DarkMode"; _install_PKG gp-dark
}

function _pComputing() {
	_msgInfo "###   Profile: Computing   ###"

	_msg "App: Code"; _install_PKG gapp-code
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Educational"; _install_PKG gapp-edu
	_msg "App: Geo"; _install_PKG gapp-geo
	_msg "App: Data"; _install_PKG gapp-data
	_msg "App: Cad"; _install_PKG gapp-cad
	_msg "App: Design"; _install_PKG gapp-design

	_msg "Profile"; _install_PKG gp-comp
}

function _pTeach() {
	_msgInfo "###   Profile: Teach   ###"

	_msg "Printer"; _install_PKG g-printerGOI
	_msg "App: Administrative"; _install_PKG gapp-adm
	_msg "App: Educational"; _install_PKG gapp-edu

	_msg "Profile"; _install_PKG gp-teach
}

function _pRadio() {
	_msgInfo "###   Profile: Radio   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Photo"; _install_PKG gapp-photo
	_msg "App: Design"; _install_PKG gapp-design
	_msg "App: VFX"; _install_PKG gapp-vfx
	_msg "App: Video"; _install_PKG gapp-video
	_msg "Printer"; _install_PKG g-printerGOI
	_msg "App: CLI"; _install_PKG gapp-cli

	_msg "Profile"; _install_PKG gp-radio
	_msg "DarkMode"; _install_PKG gp-dark
}

function _pkgProfile() {
	case $profile in
		"adm") _pAdm;;
		"lib") _pLibrary;;
		"cine") _pCinema;;
		"agro") _pAgro;;
		"art") _pArt;;
		"comp") _pComputing;;
		"teach") _pTeach;;
		"radio") _pRadio;;
		*);;
	esac
}

####################################################################################################
###                                     GCHROOT INIT                                             ###
####################################################################################################

_configSys
_pkgBootstrap
_pkgCore
_pBase
_pkgProfile
_configUsers
_configBoot
_finishUp

_msgOk "###   Exiting CHROOT   ###"

sync
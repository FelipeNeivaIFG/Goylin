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
	locale-gen 1> /dev/null

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
	echo -e "${gRootPasswd}\n${gRootPasswd}" | passwd root

	_msg "admin"
	useradd -mG wheel admin
	echo -e "${gAdminPasswd}\n${gAdminPasswd}" | passwd admin

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
		"intelNoVulkan") _msg "Intel (No Vulkan Support)"; _install_PKG g-intelOld;;
		"intel") _msg "Intel"; _install_PKG g-intel;;
		"amd") _msg "AMD"; _install_PKG g-amd;;
	esac

	# _msg "AD"; _install_PKG g-ad.[LOCATION]

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

	_msg "Printer"; _install_PKG g-printer
	_msg "App: Administrative"; _install_PKG gapp-adm

	_msg "Profile"; _install_PKG gp-adm
}

function _pLibrary() {
	_msgInfo "###   Profile: Library   ###"

	_msg "App: Educational"; _install_PKG gapp-edu

	_msg "Profile"; _install_PKG gp-lib
}

function _pkgProfile() {
	case $profile in
		"adm") _pAdm;;
		"lib") _pLibrary;;
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
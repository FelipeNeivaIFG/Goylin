#!/bin/bash

set -ue # Unbound Variables || Error == exit 1

####################################################################################################
###                                        Source                                                ###
####################################################################################################

. gChroot/utils/msg.sh
. gChroot/utils/chrConf.sh
. gChroot/profiles/${IFprofile}.sh

####################################################################################################
###                                        Settings                                              ###
####################################################################################################

function _configSys() {
	_msgInfo "###  System Config  ###"

	_msg "Timezone"
	ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
	locale-gen 1> /dev/null

	if [[ "${targetType}" == "ssd" || "${targetType}" == "nvme" ]]; then
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

	_msg "Temporarily disabling mkinitcpio hooks during installation"

	mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled
	mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled
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
	chmod 777 /home/guest

	mkdir -p /home/shared/
}

function _configBoot() {
	_msgInfo "###   Boot   ###"

	_msg "Re-enabling mkinitcpio hooks"

	mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled /usr/share/libalpm/hooks/90-mkinitcpio-install.hook
	mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook

	_msg "mkinitcpio"

	mkinitcpio -P 1> /dev/null

	_msg "GRUB"

	grub-install --target=i386-pc /dev/${target} 1> /dev/null
	grub-mkconfig -o /boot/grub/grub.cfg 1> /dev/null
}

function _finishUp() {
	_msgInfo "###   Finishing Chroot   ###"

	if [ $devInstall -eq 1 ]; then
		_msgAlert "Dev Build Settings"
		systemctl disable goylinDown.service 1> /dev/null
		chattr -i /etc/hostname
		chattr -i /etc/hosts
		sed -i "s/GOITESTE/GOI-DEV-BUILD/g" /etc/hostname
		sed -i "s/GOITESTE/GOI-DEV-BUILD/g" /etc/hosts
	fi
}

####################################################################################################
###                                      PKGs                                                    ###
####################################################################################################

function _pkgBootstrap() {
	_msgInfo "Bootstraping Pacman"

	pacman -Scc --noconfirm 1> /dev/null
	pacman --disable-download-timeout --noconfirm -Syy 1> /dev/null
}

function _install_PKG() {
	pacman --disable-download-timeout --noconfirm --needed --overwrite "*" -S $1
	pacman -Scc --noconfirm 1> /dev/null

	echo
}

function _pkgCore() {
	_msgInfo "###   Core PKGs   ###"

	_msg "Core"; _install_PKG g-core

	case $cpuType in
		"intelOld") _msg "Intel (No Vulkan Support)"; _install_PKG g-intelOld;;
		"intel") _msg "Intel"; _install_PKG g-intel;;
		"amd") _msg "AMD"; _install_PKG g-amd;;
	esac

	case $gpuType in
		"nvidia") _msg "Nvidia"; _install_PKG g-nvidia;;
	esac

	_msg "Audio"; _install_PKG g-audio
	_msg "Text Fonts"; _install_PKG g-fonts
	_msg "Backgrounds"; _install_PKG g-backgrounds
	_msg "Greeter"; _install_PKG g-greeter
	_msg "Desktop"; _install_PKG g-desktop
	_msg "Acessibility"; _install_PKG g-a11y # W.I.P

	_msg "Dolphin File Manager"; _install_PKG g-dolphin
	_msg "Plasma Desktop"; _install_PKG g-plasma
	_msg "i3 WM"; _install_PKG g-i3

	_msg "SabeEssa?"; _install_PKG g-sabeEssa
	_msg "Patches"; _install_PKG g-patch # Used for quick dirty fixes
}

function _pBase() {
	_msgInfo "###   Profile: Base   ###"

	_msg "App: Base"; _install_PKG gapp-base
	_msg "Profile: Base"; _install_PKG gp-base
}

####################################################################################################
###                                     GCHROOT INIT                                             ###
####################################################################################################

_configSys
_pkgBootstrap
_pkgCore
_pBase
_pkgProfileIF
_configUsers
_configBoot
_finishUp

_msgOk "###   Exiting CHROOT   ###"

sync
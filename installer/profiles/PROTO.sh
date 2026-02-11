#!/bin/bash

set -ue # Unbound Variables || Error == exit 1

## PROTO PROFILES ##

function _setProfileIF() {
	_msg "Profile:"
	_msgOpt "1) Administrative"

	_msgOpt "*) Base"
	read -p '?: ' -e optProfile

	case $optProfile in
		1) profile="adm";;
	esac

	echo
}

##

function _pAdm() {
	_msgInfo "###   Profile: Administrative   ###"

	_msg "Printer"; _install_PKG g-printer.$IFprofile
	_msg "App: Administrative"; _install_PKG gapp-adm
	_msg "App: Wine"; _install_PKG gapp-wine

	_msg "Profile"; _install_PKG gp-adm.$IFprofile

	# if [ "$gpuType" = "none" ]; then
	# 	_msg "Name"; _install_PKG pkg-name
	# else
	# 	_msg "Name"; _install_PKG pkg-name-gpu
	# fi
}


function _pkgProfileIF() {
	# Base PROTO pkgs
	_msg "AD.IFprofile"; _install_PKG g-ad.$IFprofile
	_msg "Backgrounds.IFprofile"; _install_PKG g-backgrounds.$IFprofile

	# PROTO Profiles
	case $profile in
		"adm") _pAdm;;
		*);;
	esac
}
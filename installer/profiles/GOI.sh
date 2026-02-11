#!/bin/bash

set -ue # Unbound Variables || Error == exit 1

## GOI PROFILES ##

function _setProfileIF() {
	_msg "Profile:"
	_msgOpt "1) Administrative"
	_msgOpt "2) Library"
	_msgOpt "3) Agrotec"
	_msgOpt "4) Cinema"
	_msgOpt "5) Art"
	_msgOpt "6) Computing"
	_msgOpt "7) Teacher Laptops"
	_msgOpt "8) Radio"
	_msgOpt "9) Game"

	_msgOpt "*) Base"
	read -p '?: ' -e optProfile

	case $optProfile in
		1) profile="adm";;
		2) profile="lib";;
		3) profile="agro";;
		4) profile="cine";;
		5) profile="art";;
		6) profile="comp";;
		7) profile="teach";;
		8) profile="radio";;
		9) profile="game";;
		*) profile="base";;
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
}

function _pLib() {
	_msgInfo "###   Profile: Library   ###"

	_msg "App: Educational"; _install_PKG gapp-edu

	_msg "Profile"; _install_PKG gp-lib.$IFprofile
}

function _pAgro() {
	_msgInfo "###   Profile: Agro   ###"

	_msg "App: Wine"; _install_PKG gapp-wine
	_msg "App: Cad"; _install_PKG gapp-cad
	_msg "App: Geo"; _install_PKG gapp-geo

	if [ "$gpuType" = "none" ]; then
		_msg "App: Data"; _install_PKG gapp-data
		_msg "Profile"; _install_PKG gp-agro.$IFprofile
	else
		_msg "App: Data"; _install_PKG gapp-data-gpu
		_msg "App: Data"; _install_PKG gp-agro-gpu.$IFprofile
	fi
}

function _pCine() {
	_msgInfo "###   Profile: Cinema   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Write"; _install_PKG gapp-write
	_msg "App: Photo"; _install_PKG gapp-photo
	_msg "App: Design"; _install_PKG gapp-design
	_msg "App: Wine"; _install_PKG gapp-wine

	if [ "$gpuType" = "none" ]; then
		_msg "App: Video"; _install_PKG gapp-video
		_msg "App: VFX"; _install_PKG gapp-vfx
		_msg "Profile"; _install_PKG gp-cine.$IFprofile
	else
		_msg "App: Video"; _install_PKG gapp-video-gpu
		_msg "App: VFX"; _install_PKG gapp-vfx-gpu
		_msg "Profile"; _install_PKG gp-cine-gpu.$IFprofile
	fi

	# # For Game classes & Others
	_msg "App: Game Dev"; _install_PKG gapp-gamedev
	_msg "App: CLI"; _install_PKG gapp-cli

	_msg "DarkMode"; _install_PKG gp-dark
}

function _pArt() {
	_msgInfo "###   Profile: Art   ###"

	_msg "Printer: GOI.art"; _install_PKG g-printer.${IFprofile}.$profile
	_msg "App: Design"; _install_PKG gapp-design
	_msg "App: Photo"; _install_PKG gapp-photo

	_msg "DarkMode"; _install_PKG gp-dark
	_msg "Profile"; _install_PKG gp-art.$IFprofile
}

function _pComp() {
	_msgInfo "###   Profile: Computing   ###"

	_msg "App: Code"; _install_PKG gapp-code
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Educational"; _install_PKG gapp-edu
	_msg "App: Geo"; _install_PKG gapp-geo
	_msg "App: Cad"; _install_PKG gapp-cad
	_msg "App: Game Dev"; _install_PKG gapp-gamedev

	if [ "$gpuType" = "none" ]; then
		_msg "App: Data"; _install_PKG gapp-data
		_msg "Profile"; _install_PKG gp-comp.$IFprofile
	else
		_msg "App: Data"; _install_PKG gapp-data-gpu
		_msg "App: Data"; _install_PKG gp-comp-gpu.$IFprofile
	fi
}

function _pTeach() {
	_msgInfo "###   Profile: Teach   ###"

	_msg "Printer.GOI"; _install_PKG g-printer.$IFprofile
	_msg "App: Administrative"; _install_PKG gapp-adm
	_msg "App: Educational"; _install_PKG gapp-edu

	_msg "Profile"; _install_PKG gp-teach.$IFprofile
}

function _pMaker() {
	_msgInfo "###   Profile: Maker   ###"

	_msg "App: Design"; _install_PKG gapp-design
	_msg "App: Educational"; _install_PKG gapp-edu
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Code"; _install_PKG gapp-code

	if [ "$gpuType" = "none" ]; then
		_msg "App: Code"; _install_PKG gapp-maker
		_msg "Profile"; _install_PKG gp-maker.$IFprofile
	else
		_msg "App: Code"; _install_PKG gapp-maker-gpu
		_msg "Profile"; _install_PKG gp-maker-gpu.$IFprofile
	fi

	_msg "DarkMode"; _install_PKG gp-dark
}

function _pRadio() {
	_msgInfo "###   Profile: Radio   ###"

	_msg "App: Audio"; _install_PKG gapp-audio
	_msg "App: Photo"; _install_PKG gapp-photo
	_msg "App: Design"; _install_PKG gapp-design
	_msg "App: Video"; _install_PKG gapp-video
	_msg "App: CLI"; _install_PKG gapp-cli

	_msg "Printer.GOI"; _install_PKG g-printer.$IFprofile
	_msg "Profile"; _install_PKG gp-radio.$IFprofile
	_msg "DarkMode"; _install_PKG gp-dark
}

function _pGame() {
	_msgInfo "###   Profile: Game   ###"

	_msg "App: Educational"; _install_PKG gapp-edu
	_msg "App: CLI"; _install_PKG gapp-cli
	_msg "App: Game"; _install_PKG gapp-game

	_msg "Profile"; _install_PKG gp-game
	_msg "DarkMode"; _install_PKG gp-dark

	# Dev Only WIP
	[ $devInstall -eq 1 ] && _msg "WIP" && . gChroot/utils/wip_gExtra.sh
}

##

function _pkgProfileIF() {
	# Base GOI pkgs
	_msg "AD.GOI"; _install_PKG g-ad.$IFprofile
	_msg "Backgrounds.GOI"; _install_PKG g-backgrounds.$IFprofile

	# GOI Profiles
	case $profile in
		"adm") _pAdm;;
		"lib") _pLib;;
		"agro") _pAgro;;
		"art") _pArt;;
		"cine") _pCine;;
		"comp") _pComp;;
		"teach") _pTeach;;
		"radio") _pRadio;;
		"game") _pGame;;
		*);;
	esac
}
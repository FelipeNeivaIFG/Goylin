#!/bin/bash
# set -u # Unbound Variables == exit
set -e # Error == exit
# set -o pipefail # Error on pipe end == exit

####################################################################################################
###                                        MSGs                                                  ###
####################################################################################################

function _msgAlert() { 
	echo -e "\e[1;31m !: ${1} \e[0m"
}
function _msg() {
	echo -e "\e[1;34m >: ${1} \e[0m"
}
function _msgInfo() {
	echo -e "\e[1;33m #: ${1} \e[0m"
}
function _msgOk() {
	echo -e "\e[1;32m $: ${1} \e[0m"
}

####################################################################################################
###                                        Build                                                 ###
####################################################################################################

function _buildIso() {
	echo; _msgInfo 'Preparing ISO build'

	_msg 'Copying Releng'
	[ -d releng ] && rm -rf releng/
	cp -r /usr/share/archiso/configs/releng .

	_msg 'Adding PKGs'
	echo 'b43-firmware' >> releng/packages.x86_64
	echo 'mtr' >> releng/packages.x86_64

	_msg 'Config files to releng'
	cp -rf gReleng/. releng/

	_msg 'Copying gInstaller'
	cp -r ../installer releng/airootfs/gInstaller
	chmod a+x releng/airootfs/gInstaller/gInstaller.sh

	_msg 'Ensuring clean work folder'
	[ -d isoWork ] && rm -rf isoWork
	mkdir -v isoWork
	[ ! -d isoOut ] && mkdir -v isoOut

	echo; _msgInfo 'Starting ISO build'
	mkarchiso -v -w isoWork -o isoOut releng

	_msg 'Cleaning'
	rm -rf isoWork
	rm -rf releng
}

####################################################################################################
###                                       INIT                                                   ###
####################################################################################################

[ "$(id -u)" -ne 0 ] && _msgAlert "Run with root permissions: 'sudo !!'" && echo && exit
_buildIso

sync
echo; _msgOk 'Goylin ISO is Build!'
_msgOk '\,,/_(o.O)_\,,/'; echo
exit 1
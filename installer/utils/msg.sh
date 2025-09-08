#!/bin/bash

function _msg() { echo -e "\e[1;34m >: ${1} \e[0m"; }

function _msgAlert() { echo -e "\e[1;31m !: ${1} \e[0m"; }

function _msgInfo() { echo; echo -e "\e[1;33m #: ${1} \e[0m"; echo; }

function _msgOk() { echo; echo -e "\e[1;32m $: ${1} \e[0m"; echo; }

function _msgOpt() { echo -e "\e[1;32m -- ${1} \e[0m"; }

function _msgLogo() {
	echo "  ██████╗  ██████╗ ██╗   ██╗██╗     ██╗███╗   ██╗ "
	echo " ██╔════╝ ██╔═══██╗╚██╗ ██╔╝██║     ██║████╗  ██║ "
	echo " ██║  ███╗██║   ██║ ╚████╔╝ ██║     ██║██╔██╗ ██║ "
	echo " ██║   ██║██║   ██║  ╚██╔╝  ██║     ██║██║╚██╗██║ "
	echo " ╚██████╔╝╚██████╔╝   ██║   ███████╗██║██║ ╚████║ "
	echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝╚═╝  ╚═══╝ "
}

function _msgWelcome() {
	clear; echo
	_msgLogo
	_msg "Version: ${goylinVersion}"
	_msg "Name: ${goylinVName}"
	_msgOk "Goylin Installer"
}

function _msgDone() {
	echo
	_msgOpt "Goylin is Installed!"
	_msgOpt "\,,/_(o.O)_\,,/"
	echo
}
#!/bin/bash

function tarFiles() {
	echo " -- Compressing $1 -- "
	[ -f "${1}.tar" ] && sudo rm -rf "${1}.tar"
	[ -d "tmp-${1}" ] && sudo rm -rf "tmp-${1}"

	cp -R $1 "tmp-${1}"
	chown -R root:root "tmp-${1}"
	chmod -R a+rX "tmp-${1}"
	tar --owner=0 --group=0 -cf "${1}.tar" --directory="tmp-${1}" .
	rm -rf "tmp-${1}"
}

function zipFiles() {
	echo " -- zipping $1 -- "
	[ -f "${1}.7z" ] && sudo rm -rf "${1}.7z"
	[ -d "tmp-${1}" ] && sudo rm -rf "tmp-${1}"
	cp -R $1 "tmp-${1}"
	sudo chown -R root:root "tmp-${1}"
	7z a "${1}.7z" ${1}
	sudo rm -rf "tmp-${1}"
}
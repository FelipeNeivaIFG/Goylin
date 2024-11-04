#!/bin/bash

function tarFiles() {
    echo " -- Compressing $1 -- "
    [ -f "${1}.tar" ] && rm -rf "${1}.tar"
    [ -d "tmp-${1}" ] && rm -rf "tmp-${1}"

    cp -R $1 "tmp-${1}"
    sudo chown -R root:root "tmp-${1}"
    sudo tar cf "${1}.tar" --directory="tmp-${1}" .
    sudo rm -rf "tmp-${1}"    
}

tarFiles skel
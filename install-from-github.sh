#!/bin/bash
#
# Script to install VC3 components directly from git
#


wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py -O get-pip.py
python get-pip.py

#   PROJECT LISTS, EDIT THESE
vc3projects="credible vc3-infoservice vc3-master vc3-resource-tool vc3-client vc3-builder vc3-wrappers"
sdccprojects="sdcc-pluginmanager"

vc3root="git+https://github.com/vc3-project"
sdccroot="git+https://github.com/bnl-sdcc"

for p in $sdccprojects  ; do
    echo pip install $sdccroot/${p}.git --user --upgrade
    pip install $sdccroot/${p}.git --user --upgrade
done

for p in $vc3projects  ; do
    echo pip install $vc3root/${p}.git --user  --upgrade 
    pip install $vc3root/${p}.git --user  --upgrade 
done

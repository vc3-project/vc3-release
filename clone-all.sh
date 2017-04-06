#!/bin/bash
#
# Checks out all VC3 projects to ~git
#

gitdir=~/git
mkdir -p $gitdir
cd $gitdir

vc3root="https://github.com/vc3-project"
sdccroot="https://github.com/bnl-sdcc"
sdccprojects="plugin-manager"
vc3projects="pluginmanager credible vc3-info-service vc3-master vc3-core vc3-resource-tool"


for p in $sdccprojects  ; do  
    repo="${sdccroot}/${p}.git"
    echo $repo
    git clone $repo
done

for p in $vc3projects  ; do  
    repo="${vc3root}/${p}.git"
    echo $repo
    git clone $repo
done
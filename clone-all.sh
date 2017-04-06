#!/bin/bash
#
# Checks out all VC3 projects to ~git
#
# 

#   PROJECT LISTS, EDIT THESE
sdccprojects="plugin-manager"
vc3projects="pluginmanager credible vc3-info-service vc3-master vc3-core vc3-resource-tool vc3-client"

# 
#    EDITTING BELOW SHOULD NOT BE NEEDED
#
gitdir=~/git
mkdir -p $gitdir
cd $gitdir
vc3root="https://github.com/vc3-project"
sdccroot="https://github.com/bnl-sdcc"

for p in $sdccprojects  ; do
    if [ -d "$p" ] ; then
        echo "$gitdir/$p already exists. Pulling..."
        cd $p
        git pull
        cd ..
    else
        repo="${sdccroot}/${p}.git"
        echo $repo
        git clone $repo
    fi
done

for p in $vc3projects  ; do
    if [ -d "$p" ] ; then
        echo "$gitdir/$p already exists. Pulling..."
        cd $p
        git pull
        cd ..
    else  
        repo="${vc3root}/${p}.git"
        echo $repo
        git clone $repo
    fi
done


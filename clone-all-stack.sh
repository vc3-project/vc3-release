#!/bin/bash
#
# Checks out all VC3 projects to ~git
#

#   PROJECT LISTS, EDIT THESE
sdccprojects="sdcc-pluginmanager"
vc3projects="credible vc3-info-service vc3-master vc3-resource-tool vc3-client example-configurations vc3-builder vc3-wrappers vc3-factory-plugins"
jhoverprojects="cheroot cherrypy" 

# 
#    EDITTING BELOW SHOULD NOT BE NEEDED
#
gitdir=~/git
mkdir -p $gitdir
cd $gitdir
vc3root="https://github.com/vc3-project"
sdccroot="https://github.com/bnl-sdcc"
jhoverroot="https://github.com/jhover"

for p in $jhoverprojects  ; do
    if [ -d "$p" ] ; then
        echo "$gitdir/$p already exists. Pulling..."
        cd $p
        git pull
        cd ..
    else  
        repo="${jhoverroot}/${p}.git"
        echo $repo
        git clone $repo
    fi
done




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

p="autopyfactory"
if [ -d "$p" ] ; then
    echo "$gitdir/$p already exists. Pulling..."
    cd $p
    git pull
    cd ..
else
    repo="https://github.com/PanDAWMS/autopyfactory.git"
    echo $repo
    git clone $repo
fi



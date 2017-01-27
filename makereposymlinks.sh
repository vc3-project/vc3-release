#!/bin/bash
# 
# Creates symlinks
#
ROOTDIRS=/afs/usatlas.bnl.gov/mgmt/repo/grid
REPOS="development testing production external osg-epel-deps"
PLATS=rhel
RELS="6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8"
ARCHS=x86_64

for d in $ROOTDIRS; do
	for r in $REPOS; do
		for p in $PLATS; do
			echo "cd $d/$r/$p"
			cd $d/$r/$p
			for n in $RELS; do
				echo "ln -s 6Workstation $n"
				ln -s 6Workstation $n
			done
		done
	done
done
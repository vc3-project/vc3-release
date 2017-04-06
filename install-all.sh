#!/usr/bin/bash
#
# Setup development environment. 
#
gitdir=~/git

projects="plugin-manager credible vc3-info-service vc3-client vc3-master vc3-core vc3-resource-tool"
for p in $projects; do
    echo $p
    if [ ! -d "$gitdir/$p" ] ; then
        echo "$gitdir/$p does not exist."
        echo "Please clone project $p"
        exit 1
    fi
    cd $gitdir/$p
    echo "python setup.py install --home=~/"
    python setup.py install --home=~/
    echo "done."
done

~/bin/credible -c ~/git/credible/etc/credible.conf hostcert localhost
~/bin/credible -c ~/git/credible/etc/credible.conf certchain
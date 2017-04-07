#!/usr/bin/bash
#
# Setup development environment. Creates hostcert, admin cert, and copies them to builer locations. 
#
gitdir=~/git

projects="plugin-manager credible vc3-info-service vc3-client vc3-master vc3-core vc3-resource-tool vc3-builder"
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

credroot=~/var/credible/ssca/defaultca/intermediate/
srvroot=~/vc3-services/etc/certs

~/bin/credible -c ~/git/credible/etc/credible.conf hostcert localhost
~/bin/credible -c ~/git/credible/etc/credible.conf certchain
~/bin/credible -c ~/git/credible/etc/credible.conf usercert VC3Admin

mkdir -P $srvroot/private
cp $credroot/certs/localhost.cert.pem $credroot/certs/ca-chain.cert.pem $credroot/certs/VC3Admin.cert.pem $srvroot/
cp $credroot/private/locahost.keynopw.pem $credroot/private/VC3Admin.keynopw.pem $srvroot/private/
#!/bin/bash
#
# Setup development environment. Creates hostcert, admin cert, and copies them to builder locations. 
#
gitdir=~/git
destdir=~/

pyprojects="sdcc-pluginmanager credible vc3-info-service vc3-client vc3-master vc3-resource-tool vc3-wrappers"
makeprojects="vc3-builder"

for p in $pyprojects; do
    echo $p
    if [ ! -d "$gitdir/$p" ] ; then
        echo "$gitdir/$p does not exist."
        echo "Please clone project $p"
        exit 1
    fi
    cd $gitdir/$p
    #echo "rm -rf build"
    #rm -rf build
    echo "python setup.py install --home=$destdir"
    python setup.py install --home=$destdir && mkdir -p $destdir/etc && cp etc/*.conf etc/*.conf.sample etc/*.template  $destdir/etc
    if [ $? -ne 0 ]; then
      echo -e "\e[41mERROR: Something went wrong in $p\e[49m"
      sleep 2
    else
      echo "done."
    fi
done

for p in $makeprojects; do
    echo $p
    if [ ! -d "$gitdir/$p" ] ; then
        echo "$gitdir/$p does not exist."
        echo "Please clone project $p"
        exit 1
    fi
    cd $gitdir/$p
    echo "make all "
    make all 
    if [ $? -ne 0 ]; then
      echo -e "\e[41mERROR: Something went wrong in $p\e[49m"
      sleep 2
    else
      echo "done."
    fi

done


credroot=~/var/credible/ssca/defaultca/intermediate/
srvroot=~/vc3-services/etc/certs

~/bin/credible -c ~/git/credible/etc/credible.conf hostcert localhost
~/bin/credible -c ~/git/credible/etc/credible.conf certchain
~/bin/credible -c ~/git/credible/etc/credible.conf usercert VC3Admin

mkdir -p $srvroot/private
cp $credroot/certs/localhost.cert.pem $credroot/certs/ca-chain.cert.pem $credroot/certs/VC3Admin.cert.pem $srvroot/
cp $credroot/private/localhost.keynopw.pem $credroot/private/VC3Admin.keynopw.pem $srvroot/private/

echo "Done."
echo ""
echo "To run infoservice..."
echo "vc3-infoservice -d --conf ~/git/vc3-info-service/etc/vc3-infoservice.conf "
echo ""
echo "To run master..."
echo "vc3-master --conf ~/git/vc3-master/etc/vc3-master.conf -d "
echo ""
echo "To create a doc..."
echo "vc3-info-client -d --conf ~/git/vc3-info-service/etc/vc3-infoclient.conf --add ~/git/vc3-info-service/test/account.json"
echo ""
echo "To retrieve a doc..."
echo "vc3-info-client -d --conf ~/git/vc3-info-service/etc/vc3-infoclient.conf --getkey=user "


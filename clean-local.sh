#!/bin/bash
#
# Reset user's local PYTHON environment to default
#
#
#
PYMODULES="autopyfactory cheroot credible pluginmanager CherryPy pyOpenSSL portend vc3 tempora"
PTHTMP=~/pthtmp
DOTPTH=~/lib/python/easy-install.pth

echo "making .pth tempdir"
mkdir $PTHTMP
for PYM in $PYMODULES; do
    OUTTMP=`mktemp -p $PTHTMP tmp.XXXXXX`
    echo $PYM
    rm -rf ~/lib/python/${PYM}*
    cat $DOTPTH  | grep -v $ > $OUTTMP
    mv -v $OUTTMP $DOTPTH 
done

echo "removing $PTHTMP "
rm -rf $PTHTMP
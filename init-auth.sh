#!/bin/bash
#
# Bare bones auth initialization for VC3


echo "Generating inital default CA and making local host cert..."
echo ~/bin/credible -c ~/git/credible/etc/credible.conf -d hostcert localhost
~/bin/credible -c ~/git/credible/etc/credible.conf -d hostcert localhost > /dev/null

echo "Generating Admin VC3 User"
echo ~/bin/credible -c ~/git/credible/etc/credible.conf -d usercert VC3Admin
~/bin/credible -c ~/git/credible/etc/credible.conf -d usercert VC3Admin > /dev/null


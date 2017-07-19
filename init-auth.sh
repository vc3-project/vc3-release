#!/bin/bash
#
# Bare bones auth initialization for VC3

echo "Generating inital default CA and making local host cert..."
echo credible -c ~/git/credible/etc/credible.conf -d hostcert localhost
credible -c ~/git/credible/etc/credible.conf -d hostcert localhost > /dev/null

echo "Creating vc3-services area for certs. Copying..."
echo mkdir -p ~/vc3-services/etc/certs/private
mkdir -p ~/vc3-services/etc/certs/private
echo cp ~/var/credible/ssca/defaultca/intermediate/certs/ca-chain.cert.pem ~/vc3-services/etc/certs/
cp ~/var/credible/ssca/defaultca/intermediate/certs/ca-chain.cert.pem ~/vc3-services/etc/certs/
echo cp ~/var/credible/ssca/defaultca/intermediate/certs/localhost.cert.pem ~/vc3-services/etc/certs/
cp ~/var/credible/ssca/defaultca/intermediate/certs/localhost.cert.pem ~/vc3-services/etc/certs/
echo cp ~/var/credible/ssca/defaultca/intermediate/private/localhost.keynopw.pem ~/vc3-services/etc/certs/private/
cp ~/var/credible/ssca/defaultca/intermediate/private/localhost.keynopw.pem ~/vc3-services/etc/certs/private/

echo "Generating Admin VC3Admin User"
echo credible -c ~/git/credible/etc/credible.conf -d usercert VC3Admin
credible -c ~/git/credible/etc/credible.conf -d usercert VC3Admin > /dev/null


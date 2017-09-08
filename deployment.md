**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

	- [VC3 Deployment Instructions](#)
- [Adding keys](#)
- [Installing the repos](#)
- [Bootstrapping authentication on the Master](#)
	- [Installing Credible and setting up certificates](#)
	- [Issueing certificates](#)
- [Infoservice](#)
	- [Prerequisites](#)
	- [Installing the Infoservice](#)
	- [Starting the Infoservice](#)
- [VC3 Master](#)
	- [Installing the Master](#)
	- [Launching the Master](#)
- [VC3 Factory](#)
	- [Prerequisites](#)
	- [Installing the Factory](#)

VC3 Deployment Instructions
-------------

# Adding keys

When a piece of static infrastructure is initialized on OpenStack or AWS, it will only contain *your* public key at first. You'll need to add the public keys for other developers as well.

```
vi .ssh/authorized_keys
```

The CentOS account should, by default, have `sudo` privileges. 

----

# Installing the repos

On all pieces of the static infrastructure, you will need to install the VC3 package repository. Add the following contents to `/etc/yum.repos.d/vc3.repo`:

```
[vc3-noarch]
name=VC3
baseurl=http://build.virtualclusters.org/repo/noarch
gpgcheck=0
```

----

# Bootstrapping authentication on the Master
## Installing Credible and setting up certificates
Credible will be used to issue certificates to all VC3 components for authentication. We will only set it up on the Master, and then copy certificates and keys to other pieces of the infrastructure. 

Install credible from the repos:
```
yum install credible
```

And update `/etc/credible/credible.conf` as appropriate:

```
[credible]
storageplugin = Memory
vardir = /var/credible

[credible-ssh]
keytype = rsa
bitlength = 4096

[credible-ssca]
roottemplate=/etc/credible/openssl.cnf.root.template
intermediatetemplate=/etc/credible/openssl.cnf.intermediate.template
vardir = /var/credible
bitlength = 4096

# Test defaults.
sscaname = VC3
country = US
locality = Upton
state = NY
organization = BNL
orgunit = SDCC
email = jhover@bnl.gov
```

## Issueing certificates
Retrieve the CA Chain and generate a host certificate and key for the Master:

```
credible -c /etc/credible/credible.conf hostcert master-test.virtualclusters.org > /etc/pki/tls/certs/hostcert.pem
credible -c /etc/credible/credible.conf hostkey master-test.virtualclusters.org > /etc/pki/tls/private/hostkey.pem
credible -c /etc/credible/credible.conf certchain > /etc/pki/ca-trust/extracted/pem/vc3-chain.cert.pem
```

----

# Infoservice
## Prerequisites
As with the Master, you will need to install the VC3 repo and any public keys. 

## Installing the Infoservice

Assuming you have already configured the VC3 repos, install the following:
```
yum install epel-release -y
yum install vc3-infoservice pluginmanager python-pip openssl -y
pip install pyOpenSSL cherrypy
```

And edit config at {/etc/vc3/vc3-infoservice.conf}:
```
[DEFAULT]
loglevel = debug

[netcomm]
chainfile=/etc/pki/ca-trust/extracted/pem/vc3-chain.cert.pem
certfile=/etc/pki/tls/certs/hostcert.pem
keyfile=/etc/pki/tls/private/hostkey.pem

sslmodule=pyopenssl
httpport=20333
httpsport=20334

[persistence]
plugin = DiskDump

[plugin-diskdump]
filename=/tmp/infoservice.diskdump
```

On the *Master* host, you will need to issue certificates for the Infoservice. Copy and paste into the appropriate files:

``` 
(master)# credible -c /etc/credible/credible.conf hostcert info-test.virtualclusters.org
(infoservice)# vi /etc/pki/tls/certs/hostcert.pem
(master)# credible -c /etc/credible/credible.conf hostkey info-test.virtualclusters.org
(infoservice)# vi /etc/pki/tls/private/hostkey.pem
(master)# credible -c /etc/credible/credible.conf certchain
(infoservice)# /etc/pki/ca-trust/extracted/pem/vc3-chain.cert.pem
```

## Starting the Infoservice
For now, we'll use the sysv-init style startup scripts:
```
/etc/init.d/vc3-infoservice.init start
```

If it's running, you should see the following after `/etc/init.d/vc3-infoservice.init status`:
```
● vc3-infoservice.init.service - LSB: start and stop vc3-info-service
   Loaded: loaded (/etc/rc.d/init.d/vc3-infoservice.init; bad; vendor preset: disabled)
   Active: active (running) since Fri 2017-09-08 16:31:13 UTC; 36s ago
```

Check the logs for any ERROR statements:
```
grep "ERROR" /var/log/vc3/*log || echo "Everything OK"
```

------
# VC3 Master

## Installing the Master
The Master depends on the vc3-client and vc3-infoservice packages for the client APIs. Install them along with the plugin manager:
```
yum install vc3-client vc3-infoservice vc3-master pluginmanager -y
```

And configure `/etc/vc3/vc3-master.conf`:
```
[DEFAULT]
loglevel = debug

[master]
taskconf=/etc/vc3/tasks.conf

[credible]
credconf=/etc/credible/credible.conf

[dynamic]
plugin=Execute


[netcomm]
chainfile=/etc/pki/ca-trust/extracted/pem/vc3-chain.cert.pem
certfile=/etc/pki/tls/certs/hostcert.pem
keyfile=/etc/pki/tls/private/hostkey.pem

infohost=info-test.virtualclusters.org
httpport=20333
httpsport=20334

[core]
whitelist = cctools-catalog-server,vc3-factory
```


## Launching the Master 

Once the Infoservce has been started, you can start the VC3 Master to process requests. Make sure that the `infohost=` is pointed to the correct hostname in `/etc/vc3/vc3/master.conf`.

It may be necessary to create the vc3 log directory (_see CORE-140_):
```
mkdir -p /var/log/vc3
chown vc3: /var/log/vc3
```

Finally, start the service:
```
systemctl start vc3-master
```

You should see something similar to the following if things are working:
```
● vc3-master.service - VC3 Master
   Loaded: loaded (/usr/lib/systemd/system/vc3-master.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2017-09-08 17:38:48 UTC; 48s ago
 Main PID: 20031 (vc3-master)
   CGroup: /system.slice/vc3-master.service
           └─20031 /usr/bin/python /usr/bin/vc3-master --conf /etc/vc3/vc3-master.conf -d --log=/var/log/vc3/master.log
 ```

You can check to see if things are working with the following command:
```
grep "ERROR" /var/log/vc3/*.log || echo "Everything OK"
```

-------

# VC3 Factory
The VC3 factory launches, maintains, and destroys virtual clusters by sending and monitoring pilot jobs that contain the VC3 builder. 

## Prerequisites

As with the master and infoservice, you'll need the VC3 repo installed and public keys distributed before continuing. 

## Installing the Factory

In addition to the factory itself, you'll need to install VC3-specific plugins, the infoservice and client for APIs, and the pluginmanager. 
```
yum install autopyfactory vc3-factory-plugins vc3-client vc3-infoservice pluginmanager 
```

As before, we will need certificates issued to the Factory host:

```
(master)# credible -c /etc/credible/credible.conf hostcert info-test.virtualclusters.org
(factory)# vi /etc/pki/tls/certs/hostcert.pem
(master)# credible -c /etc/credible/credible.conf hostkey info-test.virtualclusters.org
(factory)# vi /etc/pki/tls/private/hostkey.pem
(master)# credible -c /etc/credible/credible.conf certchain
(factory)# /etc/pki/ca-trust/extracted/pem/vc3-chain.cert.pem
```

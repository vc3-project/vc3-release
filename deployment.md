VC3 Deployment Instructions
=====================

### *Table of Contents*

- [Prerequisites for all services](#prerequisites-for-all-services)
  * [Adding keys](#adding-keys)
  * [Installing the repos](#installing-the-repos)
- [Bootstrapping authentication on the Master](#bootstrapping-authentication-on-the-master)
  * [Installing Credible and setting up certificates](#installing-credible-and-setting-up-certificates)
  * [Issueing certificates](#issueing-certificates)
- [VC3 Infoservice](#vc3-infoservice)
  * [Prerequisites](#prerequisites)
  * [Installing the Infoservice](#installing-the-infoservice)
  * [Starting the Infoservice](#starting-the-infoservice)
- [VC3 Master](#vc3-master)
  * [Installing the Master](#installing-the-master)
  * [Launching the Master](#launching-the-master)
- [VC3 Factory](#vc3-factory)
  * [Prerequisites](#prerequisites-1)
  * [Installing the Factory](#installing-the-factory)
  * [Starting the Factory and Condor](#starting-the-factory-and-condor)
- [VC3 Web Portal](#vc3-web-portal)
  * [Prerequisites](#prerequisites-2)
  * [Installing and running Docker](#installing-and-running-docker)
  * [Issuing a certificate with Let's Encrypt](#issuing-a-certificate-with-let-s-encrypt)
  * [Installing the web portal](#installing-the-web-portal)
  * [Installing the secrets](#installing-the-secrets)
  * [Running the container](#running-the-container)

# Prerequisites for all services 

## Adding keys

When a piece of static infrastructure is initialized on OpenStack or AWS, it will only contain *your* public key at first. You'll need to add the public keys for other developers as well.

```
vi .ssh/authorized_keys
```

The CentOS account should, by default, have `sudo` privileges. 

----

## Installing the repos

On all pieces of the static infrastructure, you will need to install the VC3 package repository. Add the following contents to `/etc/yum.repos.d/vc3.repo`:

```
[vc3-x86_64]
name=VC3 x86_64
baseurl=http://build.virtualclusters.org/production/x86_64
gpgcheck=0
[vc3-noarch]
name=VC3 noarch
baseurl=http://build.virtualclusters.org/production/noarch
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
Note: If you are renewing certificates, backup old ssca first, before running credible:

```
# mv /var/credible/ssca /var/credible/ssca-backup
```

----

# VC3 Infoservice
## Prerequisites
As with the Master, you will need to install the VC3 repo and any public keys. 

## Installing the Infoservice

Assuming you have already configured the VC3 repos, install the following:
```
yum install epel-release -y
yum install vc3-infoservice pluginmanager python-pip openssl -y
pip install pyOpenSSL CherryPy==11.0.0
```

And edit config at `/etc/vc3/vc3-infoservice.conf`:
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
Due to a bug (CORE-261), we need to create `/var/log/vc3`
```
mkdir -p /var/log/vc3
```

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
The Master depends on the vc3-client and vc3-infoservice packages for the client APIs. We also need ansible and the VC3 playbooks to configure nodes. Install them along with the plugin manager:
```
yum install vc3-client vc3-infoservice vc3-master pluginmanager ansible vc3-playbooks -y
```

If using OpenStack for dynamic head node provisioning, you'll also need python-novaclient from the OpenStack repositories. 
```
yum install centos-release-openstack-ocata -y
yum install python-novaclient -y
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

You will also need to modify the client config at `/etc/vc3/vc3-client.conf`:
```
[DEFAULT]
logLevel = warn

[netcomm]
chainfile=/etc/pki/ca-trust/extracted/pem/vc3-chain.cert.pem
certfile=/etc/pki/tls/certs/hostcert.pem
keyfile=/etc/pki/tls/private/hostkey.pem

infohost=info-test.virtualclusters.org
httpport=20333
httpsport=20334
```

Finally, configure the Master for Openstack/Ansible in `/etc/vc3/tasks.conf`:
```
[DEFAULT]
# in seconds
polling_interval = 120

[vc3init]
taskplugins = InitInstanceAuth,HandlePairingRequests

[vcluster-lifecycle]
# run at least once per vcluster-requestcycle
taskplugins = InitResources,HandleAllocations
polling_interval = 45


[vcluster-requestcycle]
taskplugins = HandleRequests
polling_interval = 60

[consistency-checks]
taskplugins = CheckAllocations

[access-checks]
taskplugins = CheckResourceAccess
polling_interval = 360


[vcluster-headnodecycle]

taskplugins = HandleHeadNodes
polling_interval =  10

username = myosuser
password = secret
user_domain_name    = default
project_domain_name = default
auth_url = http://10.32.70.9:5000/v3

#CentOS 7 vanilla minimal install
#node_image            = 730253d8-d585-43d2-b2d2-16d3af388306
#CentOS 7 minimal install + condor,cvmfs,gcc,epel,osg-oasis
node_image            = 093fd316-fffc-441c-944c-6ba2de582f8f 

#large: 2 VCPUS 4GB RAM 10 GB Disk
node_flavor           = 344f29c8-7370-49b4-aaf8-b1427582970f 
#small: 1 VCPUS 2GB RAM 10 GB Disk
#node_flavor           = 15d4a4c3-3b97-409a-91b2-4bc1226382d3

node_user             = centos
node_private_key_file = ~/.ssh/initnode
node_public_key_name  = initnode-openstack-name
node_security_groups  = ssh,default
node_network_id       = 04e64bbe-d017-4aef-928b-0c2c0dd3fc9e

node_prefix           = dev-
node_max_no_contact_time = 900
node_max_initializing_count = 3

ansible_path         = /etc/vc3/vc3-playbooks/login
ansible_playbook     = login-dynamic.yaml
ansible_debug_file   = /var/log/vc3/ansible.log
```

Note the *username* and *password* you will need to fill in. You'll also need to put the private key for root on the head nodes here under `/etc/vc3/keys`.


## Launching the Master 

Once the Infoservce has been started, you can start the VC3 Master to process requests. Make sure that the `infohost=` is pointed to the correct hostname in `/etc/vc3/vc3/master.conf`.

It may be necessary to create the vc3 log directory (_see CORE-140_) and change permissions on the Credible directory (_see CORE-144_):
```
mkdir -p /var/log/vc3
chown vc3: /var/log/vc3
mkdir -p /var/credible/ssh
chown vc3: /var/credible/ssh
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
yum install epel-release -y 
yum install autopyfactory vc3-factory-plugins vc3-client vc3-infoservice pluginmanager vc3-remote-manager vc3-builder python-paramiko -y
```

We will also need the HTCondor software. Install the public key, repo, and condor package:
```
rpm --import http://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor
curl http://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-stable-rhel7.repo > /etc/yum.repos.d/htcondor-stable-rhel7.repo
yum install condor -y
```

As before, we will need certificates issued to the Factory host:

```
(master)# credible -c /etc/credible/credible.conf hostcert apf-test.virtualclusters.org
(factory)# vi /etc/pki/tls/certs/hostcert.pem
(master)# credible -c /etc/credible/credible.conf hostkey apf-test.virtualclusters.org
(factory)# vi /etc/pki/tls/private/hostkey.pem
(master)# credible -c /etc/credible/credible.conf certchain
(factory)# vi /etc/pki/ca-trust/extracted/pem/vc3-chain.cert.pem
```

The client will need to be configured to point at the test infoservice in `/etc/vc3/vc3-client.conf`:
```
[DEFAULT]
logLevel = warn

[netcomm]
chainfile=/etc/pki/ca-trust/extracted/pem/vc3-chain.cert.pem
certfile=/etc/pki/tls/certs/hostcert.pem
keyfile=/etc/pki/tls/private/hostkey.pem

infohost=info-test.virtualclusters.org
httpport=20333
httpsport=20334
```

The factory defaults for VC3, in `/etc/autopyfactory/vc3defaults.conf`, may need to be adjusted as follows:
```
[DEFAULT]
vo = VC3
status = online
override = True
enabled = True
cleanlogs.keepdays = 7
batchstatusplugin = Condor
wmsstatusplugin = None
schedplugin = KeepNRunning, MinPerCycle, MaxPerCycle, MaxPending
sched.maxtorun.maximum = 9999
sched.maxpending.maximum = 100
sched.maxpercycle.maximum = 50
sched.minpercycle.minimum = 0
sched.keepnrunning.keep_running = 0
monitorsection = dummy-monitor
builder = /usr/local/libexec/vc3-builder

periodic_remove = periodic_remove=(JobStatus == 5 && (CurrentTime - EnteredCurrentStatus) > 3600) || (JobStatus == 1 && globusstatus =!= 1 && (CurrentTime - EnteredCurrentStatus) > 86400) || (JobStatus == 2 && (CurrentTime - EnteredCurrentStatus) > 604800)

batchsubmit.condorosgce.proxy = None
batchsubmit.condorec2.proxy = None
batchsubmit.condorec2.peaceful = True
batchsubmit.condorlocal.proxy = None
batchsubmit.condorssh.killorder = newest
batchsubmit.condorssh.peaceful = False

apfqueue.sleep = 60
batchstatus.condor.sleep = 25
```

Likewise, the main `autopyfactory.conf` needs to be adjusted:

```
# =================================================================================================================
#
# autopyfactory.conf Configuration file for main Factory component of AutoPyFactory.
#
# Documentation:
#   https://twiki.grid.iu.edu/bin/view/Documentation/Release3/AutoPyFactory
#   https://twiki.grid.iu.edu/bin/view/Documentation/Release3/AutoPyFactoryConfiguration#5_2_autopyfactory_conf
#
# =================================================================================================================

# template for a configuration file
[Factory]

factoryAdminEmail = neo@matrix.net
factoryId = MYSITE-hostname-sysadminname
factorySMTPServer = mail.matrix.net
factoryMinEmailRepeatSeconds = 43200
factoryUser = autopyfactory
enablequeues = True

queueConf = file:///etc/autopyfactory/queues.conf
queueDirConf = None
proxyConf = /etc/autopyfactory/proxy.conf
authmanager.enabled = True
proxymanager.enabled = True
proxymanager.sleep = 30
authmanager.sleep = 30
authConf = /etc/autopyfactory/auth.conf
monitorConf = /etc/autopyfactory/monitor.conf
mappingsConf = /etc/autopyfactory/mappings.conf

cycles = 9999999
cleanlogs.keepdays = 14

factory.sleep=30
wmsstatus.panda.sleep = 150
wmsstatus.panda.maxage = 360
wmsstatus.condor.sleep = 150
wmsstatus.condor.maxage = 360
batchstatus.condor.sleep = 150
batchstatus.condor.maxage = 360

baseLogDir = /home/autopyfactory/factory/logs
baseLogDirUrl = http://myhost.matrix.net:25880

logserver.enabled = True
logserver.index = True
logserver.allowrobots = False

# Automatic (re)configuration
config.reconfig = True
config.reconfig.interval = 30
config.queues.plugin = File, VC3
config.auth.plugin = File, VC3

config.queues.vc3.vc3clientconf = /etc/vc3/vc3-client.conf
config.queues.vc3.tempfile = ~/queues.conf.tmp

# For static central factory, use 'all' and will check all requests.
config.queues.vc3.requestname = all
config.auth.vc3.vc3clientconf = /etc/vc3/vc3-client.conf
config.auth.vc3.tempfile = ~/auth.conf.tmp
config.auth.vc3.requestname = all

# For the factory-level monitor plugin VC3
monitor = VC3
monitor.vc3.vc3clientconf = /etc/vc3/vc3-client.conf
```

## Starting the Factory and Condor
Once the Factory, Condor, and the builder have been installed on the factory host, you'll need to start the services:
```
service condor start
service autopyfactory start
```

As usual, check for any errors in the factory startup:
```
grep "ERROR" /var/log/autopyfactory/*.log || echo "Everything OK"
```

## Monitoring the pilots
We use a graphite server provided by MWT2 to plot time series data. Create the monitoring script in `/usr/local/bin/monitor-pilots.sh`:
```
#!/bin/bash
condor_q -nobatch -global -const 'Jobstatus == 1' -long | grep "MATCH_APF" | sort | uniq -c | sed 's/\"//g' |awk -v date=$(date +%s) -v hostname=$(hostname | tr '.' '_') '{ print "condor.factory."hostname".idle." $4,$1,date}' | nc -w 30 graphite.mwt2.org 2003
condor_q -nobatch -global -const 'Jobstatus == 2' -long | grep "MATCH_APF" | sort | uniq -c | sed 's/\"//g' |awk -v date=$(date +%s) -v hostname=$(hostname | tr '.' '_') '{ print "condor.factory."hostname".running." $4,$1,date}' | nc -w 30 graphite.mwt2.org 2003
```

Make it executable, install `nc` if necessary, and test for any errors:
```
chmod +x /usr/local/bin/monitor-pilots.sh
yum install nc -y
/usr/local/bin/monitor-pilots.sh
```

If successful, there should be no output. Finally add it to root's crontab (`crontab -e` as root) with the following cron entry:
```
* * * * * /usr/local/bin/monitor-pilots.sh
```

------
# VC3 Web Portal
The VC3 web portal is a flask application that integrates the VC3 client APIs to give end-users a GUI for instantiating, running and terminating virtual clusters, registering resources and allocations, managing projects, and more.

## Prerequisites
For the host, you will need to install the development public keys and issue certs by the VC3 master. 

All of the web portal's non-secret dependencies are included in a Docker container. However, you will need the Docker engine running, as well as a certificate issued by LetsEncrypt or another CA if you want the website to actually be visible over HTTPS without warnings.

## Installing and running Docker
You will first need to install EPEL and the Docker engine
```
yum install epel-release -y
yum install docker -y
```
And start the service:
```
systemctl start docker 
systemctl status docker
```

If it's working, you should see something like this:
```
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2017-09-11 19:23:18 UTC; 2s ago
     Docs: http://docs.docker.com
 Main PID: 16879 (dockerd-current)
 ```

## Issuing a certificate with Let's Encrypt
We use Certbot to issue SSL certificates that have been trusted by Let's Encrypt. First, install Cerbot:
```
yum install certbot -y
```

Next, run `certbot certonly` and go through the prompts:
```
[root@www-test ~]# certbot certonly
Saving debug log to /var/log/letsencrypt/letsencrypt.log

How would you like to authenticate with the ACME CA?
-------------------------------------------------------------------------------
1: Spin up a temporary webserver (standalone)
2: Place files in webroot directory (webroot)
-------------------------------------------------------------------------------
Select the appropriate number [1-2] then [enter] (press 'c' to cancel): 1
Enter email address (used for urgent renewal and security notices) (Enter 'c' to
cancel):lincolnb@uchicago.edu
Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org

-------------------------------------------------------------------------------
Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf. You must agree
in order to register with the ACME server at
https://acme-v01.api.letsencrypt.org/directory
-------------------------------------------------------------------------------
(A)gree/(C)ancel: A

-------------------------------------------------------------------------------
Would you be willing to share your email address with the Electronic Frontier
Foundation, a founding partner of the Let's Encrypt project and the non-profit
organization that develops Certbot? We'd like to send you email about EFF and
our work to encrypt the web, protect its users and defend digital rights.
-------------------------------------------------------------------------------
(Y)es/(N)o: n
Please enter in your domain name(s) (comma and/or space separated)  (Enter 'c'
to cancel):www-test.virtualclusters.org
Obtaining a new certificate
Performing the following challenges:
tls-sni-01 challenge for www-test.virtualclusters.org
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at
   /etc/letsencrypt/live/www-test.virtualclusters.org/fullchain.pem.
   Your cert will expire on 2017-12-10. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

Take note of the fullchain location, e.g. `/etc/letsencrypt/live/www-test.virtualclusters.org/fullchain.pem`. You will need this location for the Container.

Note: If you are renewing your web certificates, stop nginx and the web server first.

```
systemctl stop ngninx
systemctl stop webssite
```
After you are done runnig certbot, restart services:
```
systemctl start ngninx
systemctl start webssite
```



## Installing the web portal
First, install git
```
yum install git -y
```

Then clone the web portal: 
```
cd ~
git clone https://github.com/vc3-project/vc3-website-python
```

## Installing the secrets
You'll need 3 sets of secrets, at the following locations:
 * `/root/secrets/$(hostname)/`
 * `/root/secrets/portal.conf` 
 * `/root/secrets/vc3/`
    
Docker can have unusual behavior with symbolic links, so it's best to just copy the WWW certs into place:
    
```
mkdir -p /root/secrets/$(hostname)
cp -rL /etc/letsencrypt/live/$(hostname)/* /root/secrets/$(hostname)
```

The `portal.conf` should be obtained from the VC3 developers, or re-issued from Globus if necessary.

For the VC3 certificates, you'll need to issue them with the Master as usual. The container expects the following filenames:
 * `localhost.cert.pem`
 * `localhost.keynopw.pem`
 * `vc3chain.pem`

As before:

```
(master)# credible -c /etc/credible/credible.conf hostcert apf-test.virtualclusters.org
(www)# vi /root/secrets/vc3/localhost.cert.pem
(master)# credible -c /etc/credible/credible.conf hostkey apf-test.virtualclusters.org
(www)# vi /root/secrets/vc3/localhost.keynopw.pem
(master)# credible -c /etc/credible/credible.conf certchain
(www)# vi /root/secrets/vc3/vc3chain.pem
```
Note: For dev, use `/root/vc3-website/secrets/vc3`

## Running the container
Once you have issued your certificates, you'll need to deploy the container and mount the secrets into it at run-time. We intentionally separate secrets such that everything else can be dumped into Github.

Use the following systemd file
```
[Unit]
Description=VC3 Development Website
After=syslog.target network.target

[Service]
Type=simple
ExecStartPre=/usr/local/bin/update_dev_code.sh
ExecStart=/usr/bin/docker run --rm --name vc3-portal -p 80:8080 -p 443:4443 -v /root/vc3-website/secrets/www-dev.virtualclusters.org:/etc/letsencrypt/live/virtualclusters.org -v /root/vc3-website/secrets/portal.conf:/srv/www/vc3-web-env/portal/portal.conf -v /root/vc3-website/secrets/vc3:/srv/www/vc3-web-env/etc/certs -v /root/vc3-website-python:/srv/www/vc3-web-env virtualclusters/vc3-portal:latest
ExecReload=/usr/bin/docker restart vc3-portal
ExecStop=/usr/bin/docker stop vc3-portal
```


Once placed in `/etc/systemd/system/website.service`, `systemctl start`, `systemctl stop`, and `systemctl restart` will do the appropriate things.


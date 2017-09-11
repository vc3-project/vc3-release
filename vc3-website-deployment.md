# VC3 Website Infrastructure
### Notes and upgrade procedure

*Table of Contents*
* [Intro](#intro)
* [Running](#running)
* [Updating the development website](#updating-the-development-website)
* [Updating the development container](#updating-the-development-container)
----
## Intro
The VC3 website uses a Docker container to run the portal via NGINX + UWSGI. 

Almost everything needed to launch the VC3 website lives here:  https://github.com/vc3-project/vc3-web-docker

The Dockerfile describes all software dependencies needed to build the container and launches nginx and uwsgi via supervisord - a process supervisor utility.

External configuration files, such as nginx.conf, supervisord.conf, uwsgi_params, vc3-client.conf, etc are copied into the container’s root filesystem at build time. 

Secrets, such as the Globus portal configuration and HTTPS certificates are not in this repo - and should never be. They must be mounted into the container at boot time.

All services are listening on unprivileged ports inside of the container, which are then mapped onto privileged ports on the host.

------

## Running
To run the VC3 website development container, run the following:
```
docker run --rm --name vc3-portal -p 80:8080 -p 443:4443 -v /root/vc3-website/secrets/www-dev.virtualclusters.org:/etc/letsencrypt/live/virtualclusters.org -v /root/vc3-website/secrets/portal.conf:/srv/www/vc3-web-env/portal/portal.conf -v /root/vc3-website/secrets/vc3:/srv/www/vc3-web-env/etc/certs -v /root/vc3-website-python:/srv/www/vc3-web-env virtualclusters/portal:latest
````


The source paths in the invocation will need to be replaced with the locations of the files on your local system. 

You will need to replace `/root/vc3-website/secrets/www-dev.virtualclusters.org` with your own HTTPS certificates directory. It is OK if they are self-signed. However, the following *must* be present:
 * `cert.pem` - Certificate
 * `chain.pem` - CA certificate chain
 * `fullchain.pem` - CA Certificate chain + certificate
 * `privkey.pem` - Private key
 * `/root/vc3-website/secrets/portal.conf` - Globus portal configuration file. Must contain a SERVER_NAME that matches the Globus callback, plus secret key.

Additionally, you will need VC3-specific secrets to be stored in `/root/vc3-website/secrets/vc3`, which must be issued by the VC3 Master. Within that directory, the following must be present:
 * `localhost.cert.pem` - Certificate
 * `localhost.keynopw.pem` - Private key 
 * `vc3chain.pem` - CA Certificate Chain

Finally, the VC3 website code must be mounted into the container if you intend to use a dev branch other than what the container was built with:
 * `/root/vc3-website-python`

-----

## Updating the development website

On www-dev.virtualclusters.org, this container currently runs in a tmux session as root until we write a systemd unit file for it and add webhook support. 

To upgrade, we attach to the session, Ctrl-C the running container, pull the latest vc3-website code and re-run the container:
```
# tmux attach
(once attached, hit Ctrl-C)
# cd /root/vc3-website-python; git pull origin; docker pull virtualclusters/portal:latest; docker run --rm --name vc3-portal -p 80:8080 -p 443:4443 -v /root/vc3-website/secrets/www-dev.virtualclusters.or
g:/etc/letsencrypt/live/virtualclusters.org -v /root/vc3-website/secrets/portal.conf:/srv/www/vc3-web-env/portal/portal.conf -v /root/vc3-website/secrets/vc3:/srv/www/vc3-web-env/etc/certs -v /root/vc3-website-python:/srv/www/vc3-web-env virtualclusters/portal:latest
```


If successful, you should see output similar to the following:
```
2017-08-31 15:01:24,606 CRIT Supervisor running as root (no user in config file)
2017-08-31 15:01:24,608 INFO supervisord started with pid 1
2017-08-31 15:01:25,615 INFO spawned: 'nginx' with pid 7
2017-08-31 15:01:25,617 INFO spawned: 'uwsgi' with pid 8
[uWSGI] getting INI configuration from /etc/uwsgi.d/vc3.ini
2017-08-31 15:01:26,657 INFO success: nginx entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2017-08-31 15:01:26,657 INFO success: uwsgi entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
```

---

## Updating the development container

At time it may be necessary to update the VC3 web container itself, e.g., to update the client libraries.

First, clone or pull from the upstream repo
```
# git clone https://github.com/vc3-project/vc3-web-docker
```

Make your changes, and then trigger a Docker build. Make sure you update LABEL version, otherwise Docker may not pick up your changes (due to caching). 
```
# docker build .
```

When it finishes successfully (it should!), you’ll need to tag a release with the ID of the container:
```
Successfully built ba3c25791a5
# docker tag -f ba3c25791a52 virtualclusters/vc3-base:latest
```

And then push to the Docker hub (you will need to be in the virtualclusters organization and configure docker for remote pushes - not covered here):
```
# docker push virtualclusters/vc3-base:latest
```

Please also push any changes to Github, or they may be overwritten next time:
```
# git commit -a -m “update”
# git push origin
```


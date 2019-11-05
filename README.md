## Docker Multi-daemon on systemd

### FAQs:

 - Q: Is this for Windows/Mac OS X docker?
 - A: No. Good luck!
  
 - Q: Can you run multiple docker daemons on a single linux host?
 - A: Yes! It's "experimental" in the eyes of docker, however.

 - Q: Can you run multiple docker daemons listening on different network interfaces?
 - A: Yes! This is exactly why tried to make this work! This is the functionality that I want from traditional Solaris zones in linux containers.
 
 - Q: Do you have to use different users to do this?
 - A: No! You can create a service for each (virtual/physical) network interface.

 - Q: Who is asking these questions?
 - A: Me, at first.

 - Q: What works?
 - A:
    1) Starting the daemon
    2) Starting another daemon
    3) Managing the docker daemons via tcp/unix sockets
    4) Binding container ports to specified @network interface

 - Q: What doesn't work?
 - A:
    1) Managing the additional docker daemon's via tcp remotely, without explicit iptables forwarding, if you are using a virtual bridge
    2) Specifying a single daemon.json, /etc/sysconfig/docker file with variables
    3) I have not tested ipv6, so assume ip6tables doesn't work yet
    4) Adding addtional networks. I haven't tested that either.

## The problem

I wanted to run my docker daemon, and listen/connect from different vlans/subnets over networks, without setting up docker swarm. I have a test environment,
and I thought that docker/linux containers would do networking in a similar fashion to Solaris zones. Not quite... Trying to get the docker daemon
to listen on different vlan+physical interfaces, when previously they were all off the same physical network interface, just didn't work. This wasn't a problem
on my other test server, and it isn't really a well documented part of the docker documentation (That is a mouthful).

I tried all sorts of manual iptables and network routing shenanigans, but it just was a total mess, and barely worked the way I wanted. You also can't
automate a mess. I absolutely did not want to create a virtual machine to wrap just a couple containers in, as that would defeate the my purpose of 
using docker as an application service wrapper. 

## The solution

I found this super helpful guide, which most of this work is based on: <https://www.jujens.eu/posts/en/2018/Feb/25/multiple-docker/> 
It uses fedora, and I am not using fedora or redhat/centos, so I have had to adapt a few things. I also didn't want to separate the daemons by users,
but I could do that too if I wanted. Docker doesn't have the best documentation in the world, but they do state that the feature you are about to set up
is "experimental", and it is stuck way down the bottom of the page: <https://docs.docker.com/engine/reference/commandline/dockerd/#run-multiple-daemons>

Ironically, you really want to be trying this out for yourself in a virtual machine first. This relies on systemd service files to make this work, so if
you are looking for an upstart or init docker-in-docker solution, I haven't made it (yet?). Systemd is still a poor person's SMF, but it can do some sane
things. Trouble shooting using `journalctl` and `systemctl status ...` didn't provide nearly the useful output I had expected. *LINT THAT DAEMON.JSON FILE*

Where this really makes sense, is wanting to manage the docker _daemons_ with different domains, or different TLS certificates. JuJens' Blog uses the unix
sockets for managing the docker daemons from different users, but I want to manage from a tcp+tls connection. Daemon#1 has a certificate for the IP/FQDN I want
to manage from, and Daemon#2 has 2 different IPs, and a different FQDN from the Daemon#1. You can run this with just a bog-standard un-protected tcp socket,
but even docker reminds you that that is a bad idea. (Doesn't matter too much anyway, because you have to add the iptables rules for external management explicitly)

## OK, it's complicated; A fair warning

I use btrfs, on a root drive, with /var/lib/docker mounted as a subvolume. All sorts of nasty things can and will happen to your snapshots, images, and docker container
data volumes, and installation if you aren't careful managing snapshots. If you don't plan ahead, you could lose all of your docker data, and have to start over. 

If you choose to use btrfs, my advice: don't mount /var/lib/docker under a subvolume. Maybe you want to? If it goes wrong, I can't help you.

Make sure you pay CLOSE attention to the directive "--exec-root=/var/run/docker... --data-root=/var/lib/docker... --pidfile=/var/run/docker..." 
_YOU CANNOT RUN TWO DAEMONS WITH THE SAME EXEC-ROOT, DATA-ROOT, and PIDFILE_ each and every daemon will require a separate one, along with a separate PID file. 

I have done 0 performance monitoring on any of this so far. The best advice I can give, is using the docker article to back up containers, and data volumes to be used on other hosts, 
before you try _anything_ with multiple daemons. You have been warned.

## OK, it's not that complicated, I have some scripts and some files

I cannot guarantee any of this will work on your system, please use these as a guide, along with the ascii diagrams. Docker isn't explained the best in the world,
and coming from a real UNIX background, it feels like it should be a bit more integrated that it is. But heyo, they are doing great work, and it's mostly free.
Take the playbooks, shell scripts, and configuration file snippits as a good basis, and modify what you need to suite your system/needs. 

You really want to be using docker swarm, with ingress and egress networks, and a control plane. Sometimes that is not desirable, and certain design patterns don't make that easy. 
Not everything can be cloud-y and distributed. This is the solution.

## Contributing

Fork away! I am not too invested in maintaining or updating this beyond my use cases. I am providing configuration file stubs so you can work with something useful.
RancherOS are doing some good work with docker-in-docker, and running multi-daemons, so I expect that project to have a more complete view.

## License

MIT
Copyright <2019> <CPasternack>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

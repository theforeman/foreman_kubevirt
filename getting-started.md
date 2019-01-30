
## Building development setup

In order to contribute to foreman-kubevirt integration, there is a need to setup a development system.
The development system should contain two VMs running on the development machine (i.e. laptop).

### Development machine configuration
The virtual machines are scheduled on the development machine.
Foreman development environment is located on the development machine.
Two libvirt networks are defined:
* default - provides external connectivity
* foreman - inner network that connects the nodes (foreman <--> kubevirt <--> foreman-proxy)
```
<network ipv6='yes'>
  <name>foreman</name>
  <forward mode='nat'/>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='foreman' stp='on' delay='0'/>
  <mac address='54:54:00:47:13:0b'/>
  <domain name='example.tst'/>
  <ip address='192.168.111.1' netmask='255.255.255.0'/>
</network>
```
![dev env chart](https://imgur.com/a/7EckrqU)

We'll use the following for our setup:
Operating system: CentOS 7.5
The domain: example.tst
The network to connect the VMs and serves as PXE boot network: 192.168.111.0
The network will be defined on the development machine

### VM **foreman-proxy.example.tst**
VM **foreman-proxy.example.tst** serves as the utilities vm and somewhat simulates foreman capsule.
Hostname: foreman-proxy.example.tst
IP Address: 192.168.111.12
Network interfaces:
* eth0 connected to *default* network
* eth1 connected to 'foreman' network
The following service should be installed and configured:
* foreman-proxy
* dhcpd
* tftp
* named

The output of avaiable service on such machine should look like:
```
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 192.168.111.12:8000     0.0.0.0:*               LISTEN      1015/ruby
tcp        0      0 0.0.0.0:7911            0.0.0.0:*               LISTEN      1021/dhcpd
tcp        0      0 192.168.111.12:53       0.0.0.0:*               LISTEN      1056/named
tcp        0      0 127.0.0.1:53            0.0.0.0:*               LISTEN      1056/named
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1014/sshd
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      1431/master
tcp        0      0 127.0.0.1:953           0.0.0.0:*               LISTEN      1056/named
tcp6       0      0 :::8140                 :::*                    LISTEN      1069/java
tcp6       0      0 ::1:53                  :::*                    LISTEN      1056/named
tcp6       0      0 :::21                   :::*                    LISTEN      1025/vsftpd
tcp6       0      0 :::22                   :::*                    LISTEN      1014/sshd
tcp6       0      0 ::1:25                  :::*                    LISTEN      1431/master
tcp6       0      0 ::1:953                 :::*                    LISTEN      1056/named
udp        0      0 192.168.111.12:53       0.0.0.0:*                           1056/named
udp        0      0 127.0.0.1:53            0.0.0.0:*                           1056/named
udp        0      0 0.0.0.0:67              0.0.0.0:*                           1021/dhcpd
udp        0      0 0.0.0.0:68              0.0.0.0:*                           15150/dhclient
udp        0      0 0.0.0.0:69              0.0.0.0:*                           1026/xinetd
udp6       0      0 ::1:53                  :::*                                1056/named
udp6       0      0 :::69                   :::*                                1/systemd
```

The same machine will be used to store also the installation media for Foreman, unless preferred using the web as the source.

2. VM **kubevirt.example.tst** - this vm will have the kubernetes cluster and kubevirt.
Create a guide for installing multus/flannel/ovs on top of Centos 7.5:
https://kubernetes.io/docs/setup/cri/
(For docker https://kubernetes.io/docs/setup/cri/#docker)
https://kubernetes.io/docs/setup/independent/install-kubeadm/
https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
http://kubevirt.io/2018/attaching-to-multiple-networks.html
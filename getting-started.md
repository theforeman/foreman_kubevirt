
## Building development setup

In order to contribute to foreman-kubevirt integration, there is a need to setup a development environment.
The development environment should contain two VMs running on the development machine (i.e. laptop).

### Development machine configuration
The virtual machines are scheduled on the development machine.
Foreman development environment is located on the development machine, created by following [Foreman's guide](https://theforeman.org/contribute.html) .

Two libvirt networks are defined:
* default - provides external connectivity
* foreman - inner network that connects the VMs (foreman <--> kubevirt <--> foreman-proxy). The network will serve for booting KubeVirt's VM from a PXE server.
  * Address on development machine: 192.168.111.1
  * The domain *example.tst*
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
![dev env chart](development-setup.jpg)

---

The VMs will be created based on the following settings:
Operating system: CentOS 7.5
The domain: example.tst
The network to connect the VMs and serves as PXE boot network: 192.168.111.0

### VM **foreman-proxy.example.tst**
VM **foreman-proxy.example.tst** serves as the utilities vm and somewhat simulates foreman ![capsule](https://theforeman.org/plugins/katello/2.4/user_guide/capsules/index.html).
Hostname: foreman-proxy.example.tst
IP Address: 192.168.111.12
Network interfaces:
* eth0 connected to *default* network
* eth1 connected to 'foreman' network
The following service should be installed and configured:
* foreman-proxy - connects foreman's to the required services listed below
* dhcpd - manages IP addresses for the created hosts
* tftp - manages boot files for PXE boot from foreman
* named - manages host names 
* vsftp - stores local installation media

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
Create a guide for installing multus/flannel/ovs on top of Centos 7.5.
The installation is based on the following guides:
https://kubernetes.io/docs/setup/cri/#docker
https://kubernetes.io/docs/setup/independent/install-kubeadm/
https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
http://kubevirt.io/2018/attaching-to-multiple-networks.html

### Purge KubeVirt and Kubernetes

```
export LABEL=kubevirt.io
export K8S_NAMESPACE=kube-system
export KUBEVIRT_NAMESPACE=kubevirt

for entity in deployment ds rs pods validatingwebhookconfiguration services pvc pv clusterrolebinding rolebinding roles clusterroles serviceaccounts configmaps secrets customresourcedefinitions
do
  kubectl delete $entity -l $LABEL -n $NAMESPACE
  kubectl delete $entity -l $LABEL -n $KUBEVIRT_NAMESPACE
done

kubectl delete network-attachment-definitions.k8s.cni.cncf.io --all
kubectl delete -f https://raw.githubusercontent.com/intel/multus-cni/master/images/multus-daemonset.yml
kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

RELEASE=v0.13.2
kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml

kubectl delete -f https://raw.githubusercontent.com/kubevirt/ovs-cni/master/examples/ovs-cni.yml
\rm -rf /var/lib/etcd/*
```

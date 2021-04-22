
## Building development setup

In order to contribute to foreman-kubevirt integration, there is a need to setup a development environment.
The development environment should contain two VMs running on the development machine (i.e. laptop).

### On your PC (Development machine configuration)
The virtual machines are scheduled on the development machine.
Foreman development environment is located on the development machine, created by following [Foreman's guide](https://theforeman.org/contribute.html) .

Two libvirt networks should be defined:
* default - provides external connectivity
* foreman - inner network that connects the VMs (foreman <--> kubevirt <--> foreman-proxy). The network will serve for booting KubeVirt's VM from a PXE server.
  * Address on development machine: 192.168.111.1
  * The domain *kubevirt.tst*

#### create foreman linux bridge:
```
cat > br10.xml <<EOF

<network ipv6='yes'>
  <name>foreman</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='foreman' stp='on' delay='0'/>
  <mac address='54:54:00:47:13:0b'/>
  <domain name='kubevirt.tst'/>
  <ip address='192.168.111.1' netmask='255.255.255.0'/>
</network>
EOF
```

```clickhouse
sudo virsh net-define  br10.xml
```

Make sure the bridge was created:
```clickhouse
sudo virsh -r net-dumpxml foreman

```

Auto start the bridge:
```clickhouse
sudo virsh net-autostart foreman

```
Start the bridge:
```clickhouse
sudo virsh net-start foreman

```

The following chart shows the different components of the development environment:
![dev env chart](images/development-setup.jpg)



### VM **ns1.kubevirt.tst**
VM **ns1.kubevirt.tst** serves as the utilities vm and somewhat simulates foreman [capsule](https://theforeman.org/plugins/katello/2.4/user_guide/capsules/index.html).

####requirements:
- Cpu: 2
- Memory: 4096
- Volumes:
- Disk: 20 GB
- Nics:
  - NIC1 : foreman
  - NIC2: default

####Set the hostname:
```
hostnamectl set-hostname ns1.kubevirt.tst
```

####configure the nic:
*Note - please make sure you have the same DEVICE name, if not change the DEVICE according the name of your DEVICE 
```clickhouse
cat > /etc/sysconfig/network-scripts/ifcfg-enp	 <<EOF

TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=enp1s0
DEVICE=enp1s0
ONBOOT=yes
GATEWAY=192.168.111.1
IPADDR=192.168.111.12
NETMASK=255.255.255.0
DNS=192.168.111.12
EOF

```

####Connect the ns1 to the dns:

1. Check if /etc/resolv.conf exist, if not  run: dhclient
2. Edit file /etc/resolv.conf and add this line to the end:
```
    Nameserver 192.168.111.1
```
3. Check you are connected: ping github.com

####Install smart proxy features:
* Tftp - https://computingforgeeks.com/how-to-setup-a-tftp-server-on-centos-rhel-8/
* Dhcp - https://linuxhint.com/dhcp_server_centos8/
* Dns  - https://www.linuxtechi.com/setup-bind-server-centos-8-rhel-8/

#### Install Foreman smart proxy:
Install and configure foreman smart proxy: https://github.com/theforeman/smart-proxy


The same machine will be used to store also the installation media for Foreman, unless preferred using the web as the source.

### VM **kubevirt.kubevirt.tst**

####requirements:
- Cpu: 4
- Memory: 6144
- Volumes:
- Volumes :
  Disk1: 20 GB
  Disk2: 20 GB
- Nics:
  - NIC1 : default
  - NIC2: foreman


This vm will have the kubernetes cluster and kubevirt addon installed.
The instruction of installing this node relies on the following links, based on Centos 7.5:
* https://kubernetes.io/docs/setup/independent/install-kubeadm/
* https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
* https://kubernetes.io/docs/setup/cri/#docker
* http://kubevirt.io/2018/attaching-to-multiple-networks.html
* https://github.com/kubevirt/cluster-network-addons-operator

#### Create the nics
*Note - please make sure you have the same DEVICE name, if not change the DEVICE and the file name according the name of your DEVICE


```clickhouse
cat >  /etc/sysconfig/network-scripts/ifcfg-enp2s0 <<EOF
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=enp2s0
UUID=9af55927-30ce-41a7-9eef-5d7e5555601f
DEVICE=enp2s0
ONBOOT=yes
BRIDGE=foreman
EOF

```


* Create bridge named ***foreman*** and connect to eth1 (interface that is connected to libvirt's ***foreman*** network)
```
cat > /etc/sysconfig/network-scripts/ifcfg-foreman <<EOF

TYPE=Bridge
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
IPADDR=192.168.111.13
NETMASK=255.255.255.0
GATEWAY=192.168.111.1
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=foreman
DEVICE=foreman
ONBOOT=yes
DNS=192.168.111.12
ZONE=public
HOTPLUG=no
EOF
```

### Connect the kubevirt to the dns(ns1):
Note - if /etc/resolv.conf doesn’t exists run: dhclient
Edit file /etc/resolv.conf and add this line to the end:
```
Nameserver 192.168.111.12
```

### Change the hostname:
```clickhouse
hostnamectl set-hostname kubevirt.kubevirt.tst

```

#### Configure the Firewall rules:
```
firewall-cmd --permanent --zone=public --add-port=6443/tcp 
firewall-cmd --permanent --zone=public --add-port=10250-10252/tcp 
firewall-cmd --permanent --zone=public --add-port=2379-2380/tcp 
firewall-cmd --permanent --zone=public --add-port=30000-32767/tcp
firewall-cmd --reload
# Verify the configured ports
firewall-cmd --list-all
```
#### Enable IP Forwarding:
```
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

modprobe br_netfilter
 ```

#### Install Kubernetes and KubeVirt:

 * Before moving to the next step, please Make sure to:
    - Add kubernetes repository to /etc/yum.repos.d and install kubeadm, kubelet and kubectl (see [here](https://kubernetes.io/docs/setup/independent/install-kubeadm/))
    - Install docker end make sure to run docker service (see [here](https://docs.docker.com/engine/install/))
```
kubeadm config images pull
swapoff -a # should be disabled permanantly by commenting the swap on /etc/fstab
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.111.13
systemctl enable kubelet
```

Copy kubernetes configuration file to home directory:
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Let kubernetes master serve as a node:
`kubectl taint nodes --all node-role.kubernetes.io/master-`

Install KubeVirt, Flannel and Cluster Network Operator:
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Check for latest version

# On other OS you might need to define it like
export KUBEVIRT_VERSION="v0.18.0"
# On Linux you can obtain it using 'curl' via:
export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- - | sort -V | tail -1 | awk -F':' '{print $2}' | sed 's/,//' | xargs)

kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml

# before moving to next step, please make sure that kubevirt pods are running:
kubectl get pods -n kubevirt -A

export NET_RELEASE=$(curl -s https://api.github.com/repos/kubevirt/cluster-network-addons-operator/releases | grep tag_name | grep -v -- - | sort -V  | tail -1 | awk -F':' '{print $2}' | sed 's/,//' | xargs)

kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/${NET_RELEASE}/namespace.yaml
kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/${NET_RELEASE}/network-addons-config.crd.yaml
kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/${NET_RELEASE}/operator.yaml
kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/${NET_RELEASE}/kubemacpool.yaml

cat <<EOF | kubectl create -f -
---
apiVersion: networkaddonsoperator.network.kubevirt.io/v1alpha1
kind: NetworkAddonsConfig
metadata:
  name: cluster
spec:
  imagePullPolicy: Always
  kubeMacPool: {}
  multus: {}
  linuxBridge: {}
EOF  
```

kubectl wait networkaddonsconfig cluster --for condition=Available #  you might need to run a couple times until condition met


Download ***virtctl*** tool for managing VMs on kubevirt:
```
wget https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64 -O /usr/local/bin/virtctl
chmod +x /usr/local/bin/virtctl
```

Set CPU and Memory per slice:
```
cat > /etc/systemd/system/kubelet.service.d/11-cgroups.conf <<EOF
[Service]
CPUAccounting=true
MemoryAccounting=true
EOF
```

Start kubelet service:
```
systemctl daemon-reload
systemctl restart kubelet
```

Define network attachment definition on k8s that supports 'foreman' ovs bridge:
```
cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: ovs-foreman
spec:
  config: '{
      "cniVersion": "0.3.1",
      "name": "ovs-foreman",
      "plugins" : [
        {
          "type": "bridge",
          "bridge": "foreman"
        },
        {
          "type": "tuning"
        }
      ]
    }'

EOF

```

##### Create priviledged user with cluster-role
The following will create a service account eligible for both k8s and virt resources:
```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: foreman-account
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: foreman-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: foreman-account
  namespace: default
EOF
```

Obtain the account's token by:
```
KUBE_SECRET=`kubectl get sa foreman-account -o jsonpath='{.secrets[0].name}'`
kubectl get secrets $KUBE_SECRET -o jsonpath='{.data.token}' | base64 -d | xargs
```
##### Create priviledged user with cluster-role


#####Create NFS storage class
```clickhouse
cat <<EOF | kubectl create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

```

### Create PVs
```clickhouse

export KUBEVIRT_HOST_NAME=kubevirt.kubevirt.tst
export DIR_PATH_PREFIX=/mnt/localstorage/vol

LOCAL_PV_TEMPALTE=$(cat <<-END
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-XXX
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: DIR_PATH_PREFIX
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - KUBEVIRT_HOST_NAME
END
)

for f in {1..5}
do
  local_pv=$(echo "$LOCAL_PV_TEMPALTE" | sed -e "s/XXX/$f/" -e "s/KUBEVIRT_HOST_NAME/${KUBEVIRT_HOST_NAME}/" -e "s#DIR_PATH_PREFIX#${DIR_PATH_PREFIX}$f#")
  mkdir -p ${DIR_PATH_PREFIX}$f
  echo "$local_pv" | kubectl create -f -
done
```
### Test the environment

Create VMI (Virtual Machine Instance):
```
cat <<EOF | kubectl create -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
  labels:
    special: vmi-multus
  name: vmi-multus
spec:
  domain:
    cpu:
      cores: 1
    devices:
      disks:
      - disk:
          bus: virtio
        name: vmi-multus-pvc
        bootOrder: 2
      interfaces:
      - bridge: {}
        name: ovs-foreman-net
        macAddress: de:00:00:11:11:de
        bootOrder: 1
    machine:
      type: q35
    resources:
      requests:
        memory: 512M
  networks:
  - multus:
      networkName: ovs-foreman
    name: ovs-foreman-net
  terminationGracePeriodSeconds: 0
  volumes:
  - name: vmi-multus-pvc
    containerDisk:
      image: kubevirt/fedora-cloud-registry-disk-demo
status: {}
EOF
```

To confirm the VMI was created check:
```
kubectl get vmi
```

To open a VNC console to the VM use:
```
virtctl vnc vmi-multus
```

#### Purge KubeVirt and Kubernetes
For purging the KubeVirt environment, please follow the next steps:
```
export LABEL=kubevirt.io
export NAMESPACE=kubevirt

for entity in deployment ds rs pods validatingwebhookconfiguration services pvc pv clusterrolebinding rolebinding roles clusterroles serviceaccounts configmaps secrets customresourcedefinitions
do
    kubectl delete $entity -l $LABEL -n $NAMESPACE
done

kubectl delete network-attachment-definitions.k8s.cni.cncf.io --all
kubectl delete -f https://raw.githubusercontent.com/intel/multus-cni/master/images/multus-daemonset.yml
kubectl delete -f https://raw.githubusercontent.com/intel/multus-cni/master/images/multus-daemonset.yml

export NET_RELEASE=$(curl -s https://api.github.com/repos/kubevirt/cluster-network-addons-operator/releases | grep tag_name | grep -v -- - | sort -V  | tail -1 | awk -F':' '{print $2}' | sed 's/,//' | xargs)
# kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${NET_RELEASE}/kubevirt.yaml
kubectl delete -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/${NET_RELEASE}/operator.yaml
kubectl delete -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/${NET_RELEASE}/network-addons-config.crd.yaml
kubectl delete -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/${NET_RELEASE}/namespace.yaml


kubectl delete -f https://raw.githubusercontent.com/kubevirt/ovs-cni/master/examples/ovs-cni.yml

kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml



```

For purging entire Kubernetes:
```
kubectl drain kubevirt.kubevirt.tst --delete-local-data --force --ignore-daemonsets
kubectl delete node kubevirt.kubevirt.tst
kubeadm reset --force
rm -rf /var/lib/etcd/*
```

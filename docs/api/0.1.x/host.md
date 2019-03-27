# Host API examples

## list hosts
```clickhouse
GT http://<foreman_hostname>:<port>/api/hosts/

```
## Get info on a specific host
```clickhouse
GET http://<foreman_hostname>:<port>/api/hosts/<host_id>

```
## Create a host

Creation of a host from pxe


```clickhouse
{
POST http://<foreman_hostname>:<port>/api/hosts/

body:
  "location_id" : "<location_id>",
  "organization_id" : "<organization_id>",
  "host" : {
    "name" : <"hostname">,
    "location_id" : <location_id>,
    "hostgroup_id": <hostgroup_id>,
    "organization_id" : <organization_id>,
    "mac" : "XX:XX:XX:XX:XX:XX",
    "compute_resource_id" : <compute_resource_id>,
    "provision_method":"build",
    "compute_attributes" : {
      "cores" : "1",
      "memory": <memory, value in bytes>,
      "volumes_attributes" : {"name":"gluster-default-volume", "capacity":"1"}
    },
    "operatingsystem_id": 2,
    "architecture_id" : 1,
    "interfaces_attributes": {
       "0" : {"domain_id" : "1", "name" : "chase-prevett", "subnet_id" : "3", "mac" : "XX:XX:XX:XX:XX:XX", "ip":"XX.XX.XX.XX",
             "managed" : "1", "primary" : "1", "provision" : "1",
              "type": "Nic::Managed", "virtual" : "0",
              "compute_attributes" : {"cni_provider":"multus", "network": "default"}
             }
    }
  }
}
```

* volumes_attributes: Describe the storage requirements for the virtual machine
    * name - the name of the persistent volume claim or the image
    * capacity - the amount of storage to claim when selecting a persistent volume claim

* interfaces_attributes: Describe the network configuration for the virtual machine. For each network interface contains:
   * compute_attributes
        * cni_provider - a network provider, could be multus or genie
        * network - to which network should the interface be connected, where default is the Pod network



## Update a host
```clickhouse
PUT http://<foreman_hostname>:<port>/api/hosts/<host_id>
body:
{
    "host" : {
        "compute_attributes" : {
            "cores" : "1",
            "memory": "1073741824"
        }
    }
}
```

## Host actions

### Disassociate
```
PUT http://<foreman_hostname>:<port>/api/hosts/:id/disassociate
```
### Start
```
PUT http://<foreman_hostname>:<port>/api/hosts/<id>/power
body:
{
    "power_action" => :start
}
```
### Stop
```
PUT http://<foreman_hostname>:<port>/api/hosts/<id>/power
body:
{
    "power_action" => :stop
}
```
## Delete
```
DELETE http://<foreman_hostname>:<port>/api/hosts/<id>
```

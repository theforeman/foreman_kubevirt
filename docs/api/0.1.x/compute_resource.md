# Compute resource API examples

## list compute resources

```clickhouse

GET http://<foreman_hostname>:<port>/api/compute_resources

```

## Get info on specific compute resource
```clickhouse
GET http://<foreman_hostname>:<port>/api/compute_resources/<id>
```

## Create compute resource 
```clickhouse

POST http://<foreman_hostname>:<port>/api/compute_resources/

body:
{
"compute_resource" : {
     "name" : "<provider_name>",
     "provider" : "KubeVirt",
     "hostname": "<hostname>",
     "token": "<token>" ,
     "namespace" : "<A kubernetes namespace authorized by the provided token>",
     "api_port" : "<port>",
     "ca_crt": [
          "<X509 Certification Authorities (optional)>",
          "List of strings of lines from Certificate",
          "---BEGIN-CERT---",
          "abcde982134khlkflksa",
          "judsjdsfjlsfdsafdsad",
          "---ENC-CERT---"
          ]
  }
}

```


## Update a compute resource  

```
PUT http://<foreman_hostname>:<port>/api/compute_resources/<id>

body:
{
"compute_resource" : {
     "name" : "<provider_name>",
     "hostname": "<A kubernetes namespace authorized by the provided token>",
     "token": "<token>",
     "namespace" : "<name_space>", 
     "api_port" : "<port>"
     "ca_crt": [
          "<X509 Certification Authorities (optional)>",
          "List of strings of lines from Certificate",
          "---BEGIN-CERT---",
          "abcde982134khlkflksa",
          "judsjdsfjlsfdsafdsad",
          "---ENC-CERT---"
          ]
  }
}

```

## List provider images

```clickhouse
GET http://<foreman_hostname>:<port>/api/compute_resources/<id>/available_images
```


## Associate Vms

```
PUT http://<foreman_hostname>:<port>/api/compute_resources/<id>/associate
```

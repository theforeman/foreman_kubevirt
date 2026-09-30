
# Foreman Kubevirt Plugin

The ```foreman_kubevirt ``` plugin enables managing of [KubeVirt](https://kubevirt.io) as a Compute Resource in Foreman.

* Website: [TheForeman.org](http://theforeman.org)
* Issues: [foreman Redmine](http://projects.theforeman.org/projects/kubevirt/issues/)
* Community and support: #theforeman for general support, #theforeman-dev for development chat in [Freenode](irc.freenode.net)
* Mailing lists:
    * [foreman-users](https://groups.google.com/forum/?fromgroups#!forum/foreman-users)
    * [foreman-dev](https://groups.google.com/forum/?fromgroups#!forum/foreman-dev)


## Installation

Please see the Foreman manual for appropriate instructions:

* [Foreman: How to Install a Plugin](https://theforeman.org/plugins/#2.Installation)


### Building the plugin from source
    # git clone https://github.com/theforeman/foreman_kubevirt
    # cd foreman_kubevirt
    # gem build foreman_kubevirt.gemspec # the output will be gem named foreman_kubevirt-x.y.z.gem, where x.y.z should be replaced with the actual version

### Installing the plugin

#### Installing on Red Hat, CentOS, Fedora, Scientific Linux (rpm)
    # sudo -i
    # scl enable tfm bash
    # yum -y install gcc-c++ redhat-rpm-config gcc rubygems rh-ruby25-ruby-devel-2.5 # or a matching version according to the installed ruby
    # gem install foreman_kubevirt-x.y.z.gem # replace x.y.z with the actual version

### Bundle (gem)

Add the following to bundler.d/Gemfile.local.rb in your Foreman installation directory (/usr/share/foreman by default)

    $ gem 'foreman_kubevirt'

Or simply:

    $ echo "gem 'foreman_kubevirt'" > /usr/share/foreman/bundler.d/Gemfile.local.rb

Then run `bundle install` from the same directory

#### Developing the plugin
Add the following to bundler.d/Gemfile.local.rb in your Foreman development directory

    $ gem 'foreman_kubevirt', :path => 'path to foreman_kubevirt directory'

Then run `bundle install` from the same directory

-------------------
To verify that the installation was successful, go to Foreman, top bar **Administer > About** and check *foreman_kubevirt* shows up in the **System Status** menu under the **Plugins** tab.

## Compatibility



| Foreman Version | Plugin Version | KubeVirt API Version |
| --------------- | -------------: | -------------------- |
| >= 3.13         | ~> 0.6.x       | cluster preferred version |

The current development version uses the preferred KubeVirt API version advertised by the cluster API.

## Usage
Go to **Infrastructure > Compute Resources** and click on **New Compute Resource**.
Choose the **KubeVirt provider**, and fill in all the fields.

Here is a short description of some of the fields:
* *Namespace* - the Kubernetes namespace in which Foreman manages virtual machines.
* *Token* - a bearer token authentication for HTTP(s) calls.
* *X509 Certification Authorities* - enables client certificate authentication for API server calls.

Use a dedicated ServiceAccount with only the namespaced KubeVirt, PVC, Secret,
and network attachment permissions required by this provider. StorageClass
discovery additionally needs cluster-scoped read access. Do not use a
cluster-admin token.

### How to get values of *Token* and *X509 CA* ?

#### Kubernetes
##### *Token*:

Create a bounded token for a dedicated ServiceAccount. Replace the namespace
and account name with the values from your RBAC configuration:

```
kubectl --namespace foreman-managed-vms create token foreman-kubevirt --duration=24h
```

The API server may cap the requested lifetime. Rotate the token in Foreman
before it expires. Legacy automatically generated ServiceAccount token Secrets
and non-expiring tokens are not recommended.

##### *X509 CA*:

Taken from the active kubeconfig context:
```
kubectl config view --raw --minify \
  --output='jsonpath={.clusters[0].cluster.certificate-authority-data}' | \
  base64 --decode
```

#### OpenShift
##### *Token*:

Create a bounded token for the dedicated ServiceAccount after applying the
same least-privilege RBAC described above:

```
oc --namespace foreman-managed-vms create token foreman-kubevirt --duration=24h
```

##### *X509 CA*:

Taken from the active OpenShift context:

```
oc config view --raw --minify \
  --output='jsonpath={.clusters[0].cluster.certificate-authority-data}' | \
  base64 --decode
```

## Documentation

See the [Foreman Kubevirt manuals](https://theforeman.org/plugins/foreman_kubevirt/) on the Foreman web site.

## Tests

Tests should be invoked from the *foreman* directory by:
```
# bundle exec rake test:foreman_kubevirt
```

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) 2018 Red Hat, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

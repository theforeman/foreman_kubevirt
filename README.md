
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

| Foreman Version | Plugin Version |
| --------------- | --------------:|
| >= 1.21.x       | ~> 0.1.x       |

## Usage
Go to **Infrastructure > Compute Resources** and click on **New Compute Resource**.
Choose the **KubeVirt provider**, and fill in all the fields.

Here is a short description of some of the fields:
* *Namespace* - the virtual cluster on kubernetes to which the user has permissions as cluster-admin.
* *Token* - a bearer token authentication for HTTP(s) calls.
* *X509 Certification Authorities* - enables client certificate authentication for API server calls.

### How to get values of *Token* and *X509 CA* ?

#### Kubernetes
##### *Token*:

Either list the secrets and pick the one that contains the relevant token, or select a service account:

List of secrets that contain the tokens and set secret name instead of *YOUR_SECRET*:
```
# kubectl get secrets
# kubectl get secrets YOUR_SECRET -o jsonpath='{.data.token}' | base64 -d | xargs
```

Or obtain token for a service account named 'foreman-account':
```
# KUBE_SECRET=`kubectl get sa foreman-account -o jsonpath='{.secrets[0].name}'`
# kubectl get secrets $KUBE_SECRET -o jsonpath='{.data.token}' | base64 -d | xargs
```

##### *X509 CA*:

Taken from kubernetes admin config file:
```
# cat /etc/kubernetes/admin.conf | grep certificate-authority-data: | cut -d: -f2 | tr -d " " | base64 -d
```

Or by retrieving from the secret, via the service account (in this example assuming its name is *foreman-account*):
```
# KUBE_SECRET=`kubectl get sa foreman-account -o jsonpath='{.secrets[0].name}'`
# kubectl get secret $KUBE_SECRET  -o jsonpath='{.data.ca\.crt}' | base64 -d
```

#### OpenShift
##### *Token*:

Create a privileged account named *my-account*:
```
# oc create -f https://raw.githubusercontent.com/ManageIQ/manageiq-providers-kubevirt/master/manifests/account-openshift.yml
```
Use *oc* tool for reading the token of the *my-account* service account under *default* namespace:
`# oc sa get-token my-account -n default`

##### *X509 CA*:

Taken from OpenShift admin config file:
```
# cat /etc/origin/master/openshift-master.kubeconfig | grep certificate-authority-data: | cut -d: -f2 | tr -d " " | base64 -d
```

Or by retrieving from the secret of service account *my-account* under the *default* namespace:
```
# KUBE_SECRET=`oc get sa my-account -n default -o jsonpath='{.secrets[0].name}'`
# kubectl get secret $KUBE_SECRET -n default -o jsonpath='{.data.ca\.crt}' | base64 -d
```

## Documentation

See the [Foreman Kubevirt manuals](https://theforeman.org/plugins/foreman_kubevirt/) on the Foreman web site.

## Tests

Tests should be invoked from the *foreman* directory by:
```
# bundle exec rake test:foreman_kubevirt
```

## TODO

* Implement VM Console

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

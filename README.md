# ForemanKubevirt

This plugin enables managing of Kubevirt Provider as a Compute Resource in Foreman.

## Installation

See [How_to_Install_a_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin)
for how to install Foreman plugins

## Usage
KubeVirt is implemented as a compute resource, therefore it should be added under the 'Infrastructure --> Compute Resource' menu, by creating a new provider of type 'KubeVirt'.

The compute resource UI expects a `token` as identifier of the user.
In order to obtain the tokem from a running kubevirt cluster follow:
```
# list of secrets that contain the tokens
kubectl get secrets

# Replace KUBE_SECRET with the relevant secret name
# the rest of the command will extract the token and decode it
get secrets KUBE_SECRET -o yaml | grep token: | cut -d":" -f 2 | tr -d " "  | base64 -d
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

module ForemanKubevirt
  # Example: Plugin's HostsController inherits from Foreman's HostsController
  class HostsController < ::HostsController
    # change layout if needed
    # layout 'foreman_kubevirt/layouts/new_layout'

    def new_action
      # automatically renders view/foreman_kubevirt/hosts/new_action
    end
  end
end

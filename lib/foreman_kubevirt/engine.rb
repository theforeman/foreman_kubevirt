module ForemanKubevirt
  class Engine < ::Rails::Engine
    engine_name "foreman_kubevirt"

    initializer "foreman_kubevirt.register_plugin", :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_kubevirt do
        requires_foreman ">= 1.16"
        compute_resource(ForemanKubevirt::Kubevirt)

        parameter_filter(ComputeResource, :hostname, :url)
        parameter_filter(ComputeResource, :namespace, :user)
        parameter_filter(ComputeResource, :token, :password)
        parameter_filter(ComputeResource, :ca_cert)
      end
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      require "fog/kubevirt"
    end

    initializer "foreman_kubevirt.register_gettext", after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), "locale")
      locale_domain = "foreman_kubevirt"
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end
end

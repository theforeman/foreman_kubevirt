module ForemanKubevirt
  class Engine < ::Rails::Engine
    engine_name "foreman_kubevirt"
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    initializer "foreman_kubevirt.register_plugin", :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_kubevirt do
        requires_foreman ">= 1.7"
        compute_resource(ForemanKubevirt::Kubevirt)

        parameter_filter(ComputeResource, :hostname, :url)
        parameter_filter(ComputeResource, :namespace, :user)
        parameter_filter(ComputeResource, :token, :password)
        parameter_filter(ComputeResource, :ca_cert)
      end
    end

    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*', 'app/assets/stylesheets/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last
        end
      end

    initializer 'foreman_kubevirt.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end

    initializer 'foreman_kubevirt.configure_assets', group: :assets do
      SETTINGS[:foreman_kubevirt] = { assets: { precompile: assets_to_precompile } }
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      begin
        require "fog/kubevirt"
        require "fog/compute/kubevirt/models/server"
        require File.expand_path("../../app/models/concerns/fog_extensions/kubevirt/server", __dir__)

        Fog::Compute::Kubevirt::Server.send(:include, ::FogExtensions::Kubevirt::Server)
      rescue StandardError => e
        Rails.logger.warn "Foreman-Kubevirt: skipping engine hook (#{e})"
      end
    end

    initializer "foreman_kubevirt.register_gettext", after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path("../..", __dir__), "locale")
      locale_domain = "foreman_kubevirt"
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end
end

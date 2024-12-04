module ForemanKubevirt
  class Engine < ::Rails::Engine
    engine_name "foreman_kubevirt"

    initializer "foreman_kubevirt.register_plugin", :before => :finisher_hook do |app|
      app.reloader.to_prepare do
        Foreman::Plugin.register :foreman_kubevirt do
          requires_foreman '>= 3.13'
          register_gettext

          compute_resource(ForemanKubevirt::Kubevirt)

          parameter_filter(ComputeResource, :hostname, :url)
          parameter_filter(ComputeResource, :namespace, :user)
          parameter_filter(ComputeResource, :token, :password)
          parameter_filter(ComputeResource, :ca_cert)
          parameter_filter(ComputeResource, :api_port)
        end
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

    initializer 'foreman_kubevirt.filter_parameters' do |app|
      app.config.filter_parameters += [:token]
    end

    initializer 'foreman_kubevirt.configure_assets', group: :assets do
      SETTINGS[:foreman_kubevirt] = { assets: { precompile: assets_to_precompile } }
    end

    initializer "foreman_kubevirt.add_rabl_view_path" do
      Rabl.configure do |config|
        config.view_paths << ForemanKubevirt::Engine.root.join('app', 'views')
      end
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      require "fog/kubevirt"
      require "fog/kubevirt/compute/utils/unit_converter"
      require "fog/kubevirt/compute/models/server"

      ::Api::V2::ComputeResourcesController.send :include, ForemanKubevirt::Concerns::Api::ComputeResourcesControllerExtensions
      Fog::Kubevirt::Compute::Server.send(:include, ::FogExtensions::Kubevirt::Server)

      require "fog/kubevirt/compute/models/volume"
      Fog::Kubevirt::Compute::Volume.send(:include, ::FogExtensions::Kubevirt::Volume)

      require "fog/kubevirt/compute/models/vmnic"
      Fog::Kubevirt::Compute::VmNic.send(:include, ::FogExtensions::Kubevirt::VMNic)

      require "fog/kubevirt/compute/models/networkattachmentdef"
      Fog::Kubevirt::Compute::Networkattachmentdef.send(:include, ::FogExtensions::Kubevirt::Network)
      ComputeAttribute.send :include, ForemanKubevirt::ComputeAttributeExtensions

    rescue StandardError => e
      Rails.logger.warn "Foreman-Kubevirt: skipping engine hook (#{e})"
    end
  end
end

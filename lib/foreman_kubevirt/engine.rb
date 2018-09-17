module ForemanKubevirt
  class Engine < ::Rails::Engine
    engine_name 'foreman_kubevirt'

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]

    # Add any db migrations
    initializer 'foreman_kubevirt.load_app_instance_data' do |app|
      ForemanKubevirt::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_kubevirt.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_kubevirt do
        requires_foreman '>= 1.16'
        compute_resource(ForemanKubevirt::Kubevirt)

        parameter_filter(ComputeResource, :hostname, :url)
        parameter_filter(ComputeResource, :namespace, :user)
        parameter_filter(ComputeResource, :token, :password)

        # Add permissions
        # security_block :foreman_kubevirt do
        #   permission :view_foreman_kubevirt, :'foreman_kubevirt/hosts' => [:new_action]
        # end

        # Add a new role called 'Discovery' if it doesn't exist
        # role 'ForemanKubevirt', [:view_foreman_kubevirt]

        # add menu entry
        menu :top_menu, :template,
             url_hash: { controller: :'foreman_kubevirt/hosts', action: :new_action },
             caption: 'ForemanKubevirt',
             parent: :hosts_menu,
             after: :hosts

        # add dashboard widget
        widget 'foreman_kubevirt_widget', name: N_('Foreman plugin template widget'), sizex: 4, sizey: 1
      end
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      require 'fog/kubevirt'

      begin
        Host::Managed.send(:include, ForemanKubevirt::HostExtensions)
        HostsHelper.send(:include, ForemanKubevirt::HostsHelperExtensions)
      rescue => e
        Rails.logger.warn "ForemanKubevirt: skipping engine hook (#{e})"
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanKubevirt::Engine.load_seed
      end
    end

    initializer 'foreman_kubevirt.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../../..', __FILE__), 'locale')
      locale_domain = 'foreman_kubevirt'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end
end

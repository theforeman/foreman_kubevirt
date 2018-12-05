require 'foreman/exception'

module ForemanKubevirt
  class Kubevirt < ComputeResource
    alias_attribute :hostname, :url
    alias_attribute :token, :password
    alias_attribute :namespace, :user

    def ca_cert
      attrs[:ca_cert]
    end

    def ca_cert=(key)
      attrs[:ca_cert] = key
    end

    def capabilities
      [:build]
    end

    def provided_attributes
      { :uuid => :name, :mac => :mac }
    end

    def available_images
      []
    end

    def self.provider_friendly_name
      'KubeVirt'
    end

    def to_label
      "#{name} (#{provider_friendly_name})"
    end

    def self.model_name
      ComputeResource.model_name
    end

    def test_connection(options = {})
      super
      connection_details_ok? && client.valid? && client.virt_supported?
    rescue StandardError => e
      errors[:base] << e.message
    end

    def networks
      nets = client.networkattachmentdefs
      # Add explicitly 'default' POD network
      nets << Fog::Compute::Kubevirt::Networkattachmentdef.new(name: 'default')
      nets
    end

    def find_vm_by_uuid(uuid)
      super
    rescue Fog::Kubevirt::Errors::ClientError
      raise ActiveRecord::RecordNotFound
    end

    def cni_providers
      [[_("multus"), :multus ], [_("genie"), :genie]]
    end

    # @param args[Hash] contains VM creation parameters
    #  cpu_cores[str] - the number of cpu cores
    #  memory[str] - the memory for the VM
    #  start[bool] - indicates if the vm should be started
    #  name[str] - the name of the VM
    #  interfaces_attributes[Hash] - the attributes for the interfaces, i.e.:
    #    {
    #      "0" => {
    #               "network"      => "ovs-foreman",
    #               "boot"         => "1",
    #               "cni_provider" => "multus"
    #             },
    #      "1" => {
    #               "network" => "default",
    #               "boot"    => "0"
    #             }
    #    }
    def create_vm(args = {})
      options = vm_instance_defaults.merge(args.to_hash.deep_symbolize_keys)
      logger.debug("creating VM with the following options: #{options.inspect}")

      # FIXME provide an image based on user selection and cloud init
      image = 'kubevirt/fedora-cloud-registry-disk-demo'
      init = { 'userData' => "#!/bin/bash\necho \"fedora\" | passwd fedora --stdin"}

      interfaces = []
      networks = []

      args["interfaces_attributes"].values.each do |iface|
        if iface["network"] == 'default'
          nic = {
            :bridge => {},
            :name   => 'default'
          }

          net = { :name => 'default', :pod => {} }
        else
          nic = {
            :bridge => {},
            :name   => iface["network"],
          }

          cni = iface["cni_provider"].to_sym
          net = {
            :name => iface["network"],
            cni   => { :networkName => iface["network"] }
          }
        end

        # TODO: Consider replacing with 'free' boot order, also verify uniqueness
        nic[:bootOrder] = 1 if iface["boot"] == '1'
        nic[:macAddress] = iface["mac"] if iface["mac"]
        interfaces << nic
        networks << net
      end

      begin
        client.vms.create(:vm_name     => options[:name],
                          :cpus        => options[:cpu_cores].to_i,
                          :memory_size => options[:memory].to_i / 2**20,
                          :image       => image,
                          :cloudinit   => init,
                          :networks    => networks,
                          :interfaces  => interfaces)
        client.servers.get(options[:name])
      rescue Fog::Kubevirt::Errors::ClientError => e
        raise e
      end
    end

    def destroy_vm(uuid)
      find_vm_by_uuid(uuid).destroy
    rescue ActiveRecord::RecordNotFound
      true
    end

    # TODO: remove if not changed - used for debug purpose
    def new_vm(attr = {})
      vm = super
      vm
    end

    #
    # Since 'name' is the identity/UUID of server/vm, we need to override
    # default values that assign also value for 'name' so vm_exists? will
    # return 'false'
    def vm_instance_defaults
      {
        :memory    => 1024.megabytes,
        :cpu_cores => '1'
      }
    end

    #
    # Overrding base class implementation since 'mac' is required for the created interface
    #
    def host_interfaces_attrs(host)
      host.interfaces.select(&:physical?).each.with_index.reduce({}) do |hash, (nic, index)|
        hash.merge(index.to_s => nic.compute_attributes.merge(ip: nic.ip, mac: nic.mac))
      end
    end

    # TODO: max supported values should be fetched according to namespace
    #      capabilities: kubectl get limits namespace_name
    def max_cpu_count
      16
    end

    def max_socket_count
      16
    end

    def max_memory
      64.gigabytes
    end

    def server_address
      hostname.split(':')[0]
    end

    def server_port
      hostname.split(':')[1] || 443
    end

    protected

    def client
      return @client if @client

      @client ||= Fog::Compute.new(
        :provider            => "kubevirt",
        :kubevirt_hostname   => server_address,
        :kubevirt_port       => server_port,
        :kubevirt_namespace  => namespace || 'default',
        :kubevirt_token      => token,
        :kubevirt_log        => logger,
        :kubevirt_verify_ssl => ca_cert.present?,
        :kubevirt_ca_cert    => ca_cert
      )
    rescue StandardError => e
      if e.message =~ /SSL_connect.*certificate verify failed/ ||
         e.message =~ /Peer certificate cannot be authenticated with given CA certificates/
        raise Foreman::FingerprintException.new(
          N_("The remote system presented a public key signed by an unidentified certificate authority. If you are sure the remote system is authentic, go to the compute resource edit page, press the 'Test Connection' button and submit"),
          ca_cert
        )
      else
        raise e
      end
    end

    private

    def connection_details_ok?
      errors[:url].empty? && errors[:user].empty? && errors[:password].empty?
    end
  end
end

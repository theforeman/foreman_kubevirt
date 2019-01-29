require 'foreman/exception'

module ForemanKubevirt
  class Kubevirt < ComputeResource
    alias_attribute :hostname, :url
    alias_attribute :token, :password
    alias_attribute :namespace, :user
    validates :hostname, :api_port, :namespace, :token, :presence => true

    def ca_cert
      attrs[:ca_cert]
    end

    def ca_cert=(key)
      attrs[:ca_cert] = key
    end

    def api_port
      attrs[:api_port]
    end

    def api_port=(key)
      attrs[:api_port] = key
    end


    def capabilities
      [:build, :image]
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
      client.valid? && client.virt_supported?
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

    def volumes
      client.volumes
    end

    def available_volumes
      volumes.select { |v| v.phase == 'Available' }
    end

    def volume_claims
      client.pvcs
    end

    def new_volume(attr = {})
      return unless new_volume_errors.empty?
      client.volumes.new(attr.merge(:capacity => '0G'))
    end

    def new_volume_errors
      errors = []
      errors.push _('no Persistent Volumes available on provider') if volumes.empty?
      errors
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
    # volumes_attributes[Hash] - the attributes for the persistent volume claim:
    #  If provided 'capacity' key, a new PVC will be created on volume with name
    #  specified by 'name' key.
    #  If provided only 'name', its value will be used as the PVC to servce as an
    #  existing claim of the VM.
    def create_vm(args = {})
      options = vm_instance_defaults.merge(args.to_hash.deep_symbolize_keys)
      logger.debug("creating VM with the following options: #{options.inspect}")

      if args["provision_method"] == "image"
        image = args["image_id"]
      else
        volume = args.dig(:volumes_attributes, :name)
        pvc = args.dig(:volumes_attributes, :id)
        raise "VM should be created based on Persistent Volume Claim or Image" unless (volume || pvc)

        # TODO: This supports a single PVC, but user might require for multiple pvcs
        if pvc.nil?
          capacity = args.dig(:volumes_attributes, :capacity)
          pvc = options[:name].gsub(/[._]+/,'-') + "-pvc-01"
          create_new_pvc(volume, capacity, pvc)
        end
      end

      # FIXME Add cloud-init support
      #init = { 'userData' => "#!/bin/bash\necho \"fedora\" | passwd fedora --stdin"}

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
        nic[:bootOrder] = 1 if iface["provision"] == true
        nic[:macAddress] = iface["mac"] if iface["mac"]
        interfaces << nic
        networks << net
      end

      begin
        client.vms.create(:vm_name     => options[:name],
                          :cpus        => options[:cpu_cores].to_i,
                          :memory_size => options[:memory].to_i / 2**20,
                          :image       => image,
                          :pvc         => pvc,
                          # :cloudinit   => init,
                          :networks    => networks,
                          :interfaces  => interfaces)
        client.servers.get(options[:name])
      rescue Fog::Kubevirt::Errors::ClientError => e
        raise e
      end
    end

    def create_new_pvc(volume_name, capacity, pvc_name)
      volume = volumes.get(volume_name)
      client.pvcs.create(:name          => pvc_name,
                         :namespace     => namespace,
                         :access_modes  => volume.access_modes,
                         :volume_name   => volume.name,
                         :storage_class => volume.storage_class,
                         :requests      => { :storage => capacity + "G" })
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
        hash.merge(index.to_s => nic.compute_attributes.merge(ip: nic.ip, mac: nic.mac, provision: nic.provision))
      end
    end

    def associated_host(vm)
      associate_by("mac", vm.mac)
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

    protected

    def client
      return @client if @client

      @client ||= Fog::Compute.new(
        :provider            => "kubevirt",
        :kubevirt_hostname   => hostname,
        :kubevirt_port       => api_port,
        :kubevirt_namespace  => namespace,
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
  end
end

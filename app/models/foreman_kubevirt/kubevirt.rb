require 'foreman/exception'

module ForemanKubevirt
  class Kubevirt < ComputeResource
    alias_attribute :hostname, :url
    alias_attribute :token, :password
    alias_attribute :namespace, :user
    validates :hostname, :api_port, :namespace, :token, :presence => true
    validate :test_connection

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
      %i[build image new_volume]
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

    def test_connection(_options = {})
      client&.valid? && client&.virt_supported?
    rescue StandardError => e
      errors[:base] << e.message
    end

    def networks
      client.networkattachmentdefs.all
    rescue StandardError => e
      logger.warn("Failed to retrieve network attachments definition from KubeVirt,
        make sure KubeVirt has CNI provider and NetworkAttachmentDefinition CRD deployed: #{e.message}")
      []
    end

    def find_vm_by_uuid(uuid)
      super
    rescue Fog::Kubevirt::Errors::ClientError => e
      Foreman::Logging.exception("Failed retrieving KubeVirt vm by uuid #{uuid}", e)
      raise ActiveRecord::RecordNotFound
    end

    def volumes
      client.volumes.all
    end

    def storage_classes
      client.storageclasses.all
    end

    def storage_classes_for_select
      storage_classes.map { |sc| OpenStruct.new(id: sc.name, description: "#{sc.name} (#{sc.provisioner})") }
    end

    def new_volume(attr = {})
      return unless new_volume_errors.empty?

      vol = Fog::Kubevirt::Compute::Volume.new(attr)
      vol.boot_order = 1 if attr[:bootable] == "on" || attr[:bootable] == "true"
      vol
    end

    def new_volume_errors
      errors = []
      errors.push _('no Storage Classes available on provider') if storage_classes.empty?
      errors
    end

    def cni_providers
      [[_("multus"), :multus], [_("genie"), :genie], [_("pod"), :pod]]
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
    #               "cni_provider" => "pod"
    #               "boot"         => "0"
    #             }
    #    }
    #
    # volumes_attributes[Hash] - the attributes for the persistent volume claims:
    #   {
    #     "1554394214729" => {
    #                          "storage_class" => "local-storage",
    #                          "name"          => "alvin-hinojosa1",
    #                          "capacity"      => "3",
    #                          "bootable"=>"true"
    #                        },
    #     "1554394230987" => {
    #                          "storage_class" => "local-storage",
    #                          "name"          => "alvin-hinojosa",
    #                          "capacity"=>"2"
    #                        }
    #   }
    def create_vm(args = {})
      options = vm_instance_defaults.merge(args.to_hash.deep_symbolize_keys)
      logger.debug("creating VM with the following options: #{options.inspect}")

      volumes = create_volumes_for_vm(options)

      # FIXME: Add cloud-init support
      # init = { 'userData' => "#!/bin/bash\necho \"fedora\" | passwd fedora --stdin"}

      interfaces, networks = create_network_devices_for_vm(options, volumes)

      begin
        client.vms.create(:vm_name     => options[:name],
                          :cpus        => options[:cpu_cores].to_i,
                          :memory_size => convert_memory(options[:memory] + "b", :m).to_s,
                          :volumes     => volumes,
                          # :cloudinit   => init,
                          :networks    => networks,
                          :interfaces  => interfaces)
        client.servers.get(options[:name])
      rescue Fog::Kubevirt::Errors::ClientError => e
        delete_pvcs(volumes)
        raise e
      end
    end

    def destroy_vm(vm_uuid)
      vm = find_vm_by_uuid(vm_uuid)
      delete_pvcs(vm.volumes)
      vm.destroy
    rescue ActiveRecord::RecordNotFound
      true
    end

    def host_compute_attrs(host)
      attrs = super
      attrs[:interfaces_attributes].each_value { |nic| nic["network"] = nil if nic["cni_provider"] == "pod" }
      attrs
    end

    #
    # Since 'name' is the identity/UUID of server/vm, we need to override
    # default values that assign also value for 'name' so vm_exists? will
    # return 'false'
    def vm_instance_defaults
      {
        :memory    => 1024.megabytes.to_s,
        :cpu_cores => '1'
      }
    end

    def new_interface(attr = {})
      Fog::Kubevirt::Compute::VmNic.new attr
    end

    #
    # Overrding base class implementation since 'mac' is required for the created interface
    #
    def host_interfaces_attrs(host)
      host.interfaces.select(&:physical?).each.with_index.reduce({}) do |hash, (nic, index)|
        hash.merge(index.to_s => nic.compute_attributes.merge(ip: nic.ip, mac: nic.mac, provision: nic.provision))
      end
    end

    #
    # Overrding base class implementation since 'pvc' is required
    #
    def set_vm_volumes_attributes(vm, vm_attrs)
      volumes = vm.volumes.collect do |vol|
        next unless vol.type == 'persistentVolumeClaim'

        begin
          vol.pvc = client.pvcs.get(vol.info)
          vol
        rescue StandardError => e
          # An import of a VM where one of its PVC doesn't exist
          Foreman::Logging.exception("Import VM fail: The PVC #{vol.info} does not exist for VM #{vm.name}", e)
          nil
        end
      end.compact
      vm_attrs[:volumes_attributes] = Hash[volumes.each_with_index.map { |volume, idx| [idx.to_s, volume.attributes] }]

      vm_attrs
    end

    def vm_compute_attributes(vm)
      vm_attrs = super
      interfaces = vm.interfaces || []
      vm_attrs[:interfaces_attributes] = interfaces.each_with_index.each_with_object({}) do |(interface, index), hsh|
        interface_attrs = {
          mac: interface.mac,
          compute_attributes: {
            network: interface.network,
            cni_provider: interface.cni_provider
          }
        }
        hsh[index.to_s] = interface_attrs
      end

      vm_attrs
    end

    def new_vm(attr = {})
      vm = super
      interfaces = nested_attributes_for :interfaces, attr[:interfaces_attributes]
      interfaces.map { |i| vm.interfaces << new_interface(i) }
      volumes = nested_attributes_for :volumes, attr[:volumes_attributes]
      volumes.map { |v| vm.volumes << new_volume(v) }
      vm
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

    # Converts a given memory to bytes
    #
    # @param memory - The memory of the VM to convert
    #
    def convert_memory_to_bytes(memory)
      convert_memory(memory, :b)
    end

    protected

    def client
      return @client if @client

      @client ||= Fog::Kubevirt::Compute.new(
        :kubevirt_hostname   => hostname,
        :kubevirt_port       => api_port,
        :kubevirt_namespace  => namespace,
        :kubevirt_token      => token,
        :kubevirt_log        => logger,
        :kubevirt_verify_ssl => ca_cert.present?,
        :kubevirt_ca_cert    => ca_cert
      )
    rescue OpenSSL::X509::CertificateError
      raise_certification_failure_exception
    rescue StandardError => e
      if e.message =~ /SSL_connect.*certificate verify failed/ ||
         e.message =~ /Peer certificate cannot be authenticated with given CA certificates/
        raise_certification_failure_exception
      else
        raise e
      end
    end

    def raise_certification_failure_exception
      raise Foreman::FingerprintException.new(
        N_("The remote system presented a public key signed by an unidentified certificate authority.
           If you are sure the remote system is authentic, go to the compute resource edit page, press the 'Test Connection' button and submit"),
          ca_cert
      )
    end

    private

    def verify_at_least_one_volume_provided(options)
      image = options[:image_id]
      volumes_attributes = options[:volumes_attributes]
      raise ::Foreman::Exception.new N_('VM should be created based on Persistent Volume Claim or Image') unless
        (volumes_attributes.present? || image)
    end

    def verify_booting_from_image_is_possible(volumes)
      raise ::Foreman::Exception.new N_('It is not possible to set a bootable volume and image based provisioning.') if
        volumes.any? { |_, v| v[:bootable] == "true" }
    end

    def add_volume_for_image_provision(options)
      image = options[:image_id]
      raise ::Foreman::Exception.new N_('VM should be created based on an image') unless image

      verify_booting_from_image_is_possible(options[:volumes_attributes])

      volume = Fog::Kubevirt::Compute::Volume.new
      volume.info = image
      volume.boot_order = 1
      volume.type = 'containerDisk'
      volume
    end

    def validate_volume_capacity(volumes_attributes)
      volumes_attributes.each { |_, v| raise ::Foreman::Exception.new N_('Capacity was not found') if v[:capacity].empty? }
    end

    def validate_only_single_bootable_volume(volumes_attributes)
      raise ::Foreman::Exception.new N_('Only one volume can be bootable') if volumes_attributes.select { |_, v| v[:bootable] == "true" }.count > 1
    end

    def create_new_pvc(pvc_name, capacity, storage_class)
      client.pvcs.create(:name          => pvc_name,
                         :namespace     => namespace,
                         :storage_class => storage_class,
                         :access_modes  => ['ReadWriteOnce'],
                         :requests      => { :storage => capacity + "G" })
    end

    def delete_pvcs(volumes)
      volumes.each do |volume|
        begin
          client.pvcs.delete(volume.info) if volume.type == "persistentVolumeClaim"
        rescue StandardError => e
          logger.error("The PVC #{volume.info} couldn't be delete due to #{e.message}")
        end
      end
    end

    def create_vm_volume(pvc_name, capacity, storage_class, bootable)
      create_new_pvc(pvc_name, capacity, storage_class)

      volume = Fog::Kubevirt::Compute::Volume.new
      volume.type = 'persistentVolumeClaim'
      volume.info = pvc_name
      volume.boot_order = 1 if bootable == "true"
      volume
    end

    def add_volumes_based_on_pvcs(options, image_provision)
      volumes_attributes = options[:volumes_attributes]
      return [] if volumes_attributes.blank?

      validate_volume_capacity(volumes_attributes)
      validate_only_single_bootable_volume(volumes_attributes)

      volumes = []
      vm_name = options[:name].gsub(/[._]+/, '-')
      volumes_attributes.each_with_index do |(_, v), index|
        # Add PVC as volumes to the virtual machine
        pvc_name = vm_name + "-claim-" + (index + 1).to_s
        capacity = v[:capacity]
        storage_class = v[:storage_class]
        bootable = v[:bootable] && !image_provision

        volume = create_vm_volume(pvc_name, capacity, storage_class, bootable)
        volumes << volume
      end

      volumes
    end

    # Creates volume elements for the VM based on provided parameters
    #
    # @param options[Hash] contains VM creation parameters
    #
    def create_volumes_for_vm(options)
      verify_at_least_one_volume_provided(options)

      # Add image as volume to the virtual machine
      volumes = []
      image_provision = options[:provision_method] == "image"

      volumes << add_volume_for_image_provision(options) if image_provision
      volumes.concat(add_volumes_based_on_pvcs(options, image_provision))
    end

    def create_pod_network_element
      nic = { bridge: {}, name: 'pod' }
      net = { name: 'pod', pod: {} }
      [nic, net]
    end

    def create_network_element(iface)
      nic = { bridge: {}, name: iface[:network] }
      cni = iface[:cni_provider].to_sym
      net = { :name => iface[:network], cni => { :networkName => iface[:network] } }
      [nic, net]
    end

    def create_network_devices_for_vm(options, volumes)
      interfaces = []
      networks = []

      options[:interfaces_attributes].values.each do |iface|
        if iface[:cni_provider] == 'pod'
          nic, net = create_pod_network_element
        else
          nic, net = create_network_element(iface)
        end

        if iface[:provision] == true && volumes.select { |v| v.boot_order == 1 }.empty?
          nic[:bootOrder] = 1
        end
        nic[:macAddress] = iface[:mac] if iface[:mac]
        interfaces << nic
        networks << net
      end

      [interfaces, networks]
    end

    def convert_memory(memory, unit)
      ::Fog::Kubevirt::Compute::Shared::UnitConverter.convert(memory, unit).to_i
    end
  end
end

require 'foreman/exception'
require 'fog/kubevirt/compute/models/vm_data'

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
      [:build, :image, :new_volume]
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
      client && client.valid? && client.virt_supported?
    rescue StandardError => e
      errors[:base] << e.message
    end

    def networks
      begin
        nets = client.networkattachmentdefs.all
      rescue => e
        logger.warn("Failed to retrieve network attachments definition from KubeVirt, make sure KubeVirt has CNI provider and NetworkAttachmentDefinition CRD deployed")
        nets = []
      end

      nets << Fog::Kubevirt::Compute::Networkattachmentdef.new(name: 'default')
    end

    def find_vm_by_uuid(uuid)
      super
    rescue Fog::Kubevirt::Errors::ClientError => e
      Foreman::Logging.exception("Failed retrieving KubeVirt vm by uuid #{uuid}", e)
      raise ActiveRecord::RecordNotFound
    end

    def volumes
      client.volumes
    end

    def storage_classes
      client.storageclasses
    end

    def storage_classes_for_select
      storage_classes.map { |sc| OpenStruct.new({ id: sc.name, description: "#{sc.name} (#{sc.provisioner})" }) }
    end

    def new_volume(attr = {})
      return unless new_volume_errors.empty?
      Fog::Kubevirt::Compute::Volume.new(attr)
    end

    def new_volume_errors
      errors = []
      errors.push _('no Persistent Volumes available on provider') if storage_classes.empty?
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
    #    {
    #      "storage_class" => "local-storage",
    #      "name"          => "mypvc",
    #      "capacity"      => "2",
    #      "bootable"      => "true"
    #    }
    def create_vm(args = {})
      options = vm_instance_defaults.merge(args.to_hash.deep_symbolize_keys)
      logger.debug("creating VM with the following options: #{options.inspect}")
      volumes = []

      # Add image as volume to the virtual machine
      if args["provision_method"] == "image"
        volume = Fog::Kubevirt::Compute::Volume.new
        image = args["image_id"]
        raise "VM should be created based on an image" unless image

        volume.info = image
        volume.boot_order = 1
        volume.type = 'containerDisk'
        volumes << volume
      else
        # Add PVC as volumes to the virtual machine
        pvc_name = args.dig(:volumes_attributes, :name)
        raise "VM should be created based on Persistent Volume Claim" unless pvc_name

        capacity = args.dig(:volumes_attributes, :capacity)
        storage_class = args.dig(:volumes_attributes, :storage_class)
        bootable = args.dig(:volumes_attributes, :bootable)

        # TODO: This supports a single PVC, but user might require for multiple pvcs
        volume = create_vm_volume(pvc_name, capacity, storage_class, bootable)
        volumes << volume
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
        # there is a bug with bootOrder https://bugzilla.redhat.com/show_bug.cgi?id=1687341
        # therefore adding to the condition not to boot from netwotk device if already asked
        # to boot from disk
        nic[:bootOrder] = if iface["provision"] == true && volumes.select { |v| v.boot_order == 1}.empty?
                            1
                          else
                            2
                          end
        nic[:macAddress] = iface["mac"] if iface["mac"]
        interfaces << nic
        networks << net
      end

      begin
        client.vms.create(:vm_name     => options[:name],
                          :cpus        => options[:cpu_cores].to_i,
                          :memory_size => options[:memory].to_i / 2**20,
                          :volumes     => volumes,
                          # :cloudinit   => init,
                          :networks    => networks,
                          :interfaces  => interfaces)
        client.servers.get(options[:name])
      rescue Fog::Kubevirt::Errors::ClientError => e
        delete_pvc_by_name(pvc_name)
        raise e
      end
    end

    def create_new_pvc(pvc_name, capacity, storage_class)
      client.pvcs.create(:name          => pvc_name,
                         :namespace     => namespace,
                         :storage_class => storage_class,
                         :access_modes  => [ 'ReadWriteOnce' ],
                         :requests      => { :storage => capacity + "G" })
    end

    def delete_pvc_by_name(pvc_name)
      client.pvcs.delete(pvc_name)
    end

    def delete_vm_pvcs(vm_uuid)
      find_vm_by_uuid(vm_uuid).volumes.each do |volume|
        begin
          delete_pvc_by_name(volume.info) if volume.type == "persistentVolumeClaim"
        rescue Exception => e
          logger.error("The PVC #{volume.info} couldn't be delete due to #{e.message}")
        end
      end
    end

    def create_vm_volume(pvc_name, capacity, storage_class, bootable)
      pvc = create_new_pvc(pvc_name, capacity, storage_class)

      volume = Fog::Kubevirt::Compute::Volume.new
      volume.type = 'persistentVolumeClaim'
      volume.info = pvc_name
      volume.boot_order = 1 if bootable == "true"
      volume
    end

    def destroy_vm(uuid)
      delete_vm_pvcs(uuid)
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

    def new_interface(attr = {})
      Fog::Kubevirt::Compute::VmData::VmNic.new attr
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

      @client ||= Fog::Kubevirt::Compute.new(
        :kubevirt_hostname   => hostname,
        :kubevirt_port       => api_port,
        :kubevirt_namespace  => namespace,
        :kubevirt_token      => token,
        :kubevirt_log        => logger,
        :kubevirt_verify_ssl => ca_cert.present?,
        :kubevirt_ca_cert    => ca_cert
      )
    rescue OpenSSL::X509::CertificateError => e
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
  end
end

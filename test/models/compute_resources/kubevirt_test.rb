require 'test_plugin_helper'

class ForemanKubevirtTest < ActiveSupport::TestCase
  setup do
    User.current = User.find_by login: 'admin'
  end

  def new_kubevirt_vcr
    ::FactoryBot.build(:compute_resource_kubevirt)
  end

  def mocked_client
    vms = stub
    pvcs = stub
    pvcs.stubs(:create)
    pvcs.stubs(:delete)
    servers = stub
    servers.stubs(:get)
    client = stub
    client.stubs(:vms).returns(vms)
    client.stubs(:pvcs).returns(pvcs)
    client.stubs(:servers).returns(servers)
    client
  end

  test "host_interfaces_attrs" do
    record = new_kubevirt_vcr
    host = ::FactoryBot.build(:host_kubevirt, :with_interfaces)
    result = record.host_interfaces_attrs(host)
    expected_res = { "0" => { "cni_provider" => "multus",
                          "network" => "ovs-foreman",
                          :ip => "192.168.111.200",
                          :mac => "a2:b4:a2:b2:a2:a8",
                          :provision => true } }
    assert_equal expected_res, result
  end

  describe "create_vm" do
    test "uses sanitized NIC names" do
      record = new_kubevirt_vcr
      client = mocked_client
      record.stubs(:client).returns(client)

      expected_networks = [{ :name => "default-network", :multus => { :networkName => "default/network" } }]
      expected_interfaces = [{ :bridge => {}, :name => "default-network" }]

      client.vms.expects(:create).with do |args|
        assert_equal expected_networks, args[:networks]
        assert_equal expected_interfaces, args[:interfaces]
      end

      record.create_vm({ :name => "test", :volumes_attributes => { 0 => { :capacity => "5" } }, :interfaces_attributes => { "0" => { "cni_provider" => "multus", "network" => "default/network" } } })
    end

    test "uses dataVolume for image based provisioning" do
      record = new_kubevirt_vcr
      client = mocked_client
      record.stubs(:client).returns(client)

      client.vms.expects(:create).with do |args|
        assert_equal 1, args[:volumes].length
        assert_equal 1, args[:volume_templates].length

        volume = args[:volumes].first
        assert_equal 'dataVolume', volume.type
        assert_equal 'test-root', volume.config[:name]
        assert_equal 'rootdisk', volume.name
        assert_equal 1, volume.boot_order

        volume_template = args[:volume_templates].first
        assert_equal 'DataVolume', volume_template[:kind]
        assert_equal 'test-root', volume_template[:metadata][:name]
        assert_equal 'DataSource', volume_template[:spec][:sourceRef][:kind]
        assert_equal 'default', volume_template[:spec][:sourceRef][:namespace]
        assert_equal 'template', volume_template[:spec][:sourceRef][:name]
      end

      record.create_vm({ :name => "test", :provision_method => 'image', :image_id => "default/template", :volumes_attributes => {}, :interfaces_attributes => { "0" => { "cni_provider" => "multus", "network" => "default/network" } } })
    end
  end

  describe "create_network_element" do
    test "sanitizes NIC names" do
      record = new_kubevirt_vcr
      iface = { network: "default/network", cni_provider: "multus" }
      nic, net = record.send(:create_network_element, iface)
      assert_equal "default-network", nic[:name]
      assert_equal "default-network", net[:name]
    end
  end

  describe "networks" do
    test "returns list of networksattachmentdefs" do
      Fog.mock!
      compute_resource = FactoryBot.build(:compute_resource_kubevirt)
      res = compute_resource.networks
      assert_equal 1, res.count
      assert_equal 'default/ovs-foreman', res.first.id
      assert_equal 'default/ovs-foreman', res.first.name
    end

    test "in case of exception, returns an empty array" do
      compute_resource = FactoryBot.build(:compute_resource_kubevirt)
      client = stub
      compute_resource.stubs(:client).returns(client)
      client.stubs(:networkattachmentdefs).raises(Fog::Kubevirt::Errors::ClientError.new)
      res = compute_resource.networks
      assert_equal 0, res.count
    end
  end

  describe "volumes" do
    test "returns empty array when error is raised" do
      Fog.mock!
      compute_resource = new_kubevirt_vcr
      client = stub
      compute_resource.stubs(:client).returns(client)
      client.stubs(:volumes).raises(Fog::Kubevirt::Errors::ClientError.new)
      assert_empty compute_resource.volumes
    end
  end

  describe "storage_classes" do
    test "returns empty array when error is raised" do
      Fog.mock!
      compute_resource = new_kubevirt_vcr
      client = stub
      compute_resource.stubs(:client).returns(client)
      client.stubs(:storageclasses).raises(Fog::Kubevirt::Errors::ClientError.new)
      assert_empty compute_resource.storage_classes
    end
  end

  describe "find_vm_by_uuid" do
    test "it finds the vm" do
      Fog.mock!
      compute_resource = FactoryBot.build(:compute_resource_kubevirt)
      res = compute_resource.find_vm_by_uuid("robin-rykert.example.com")
      assert_equal "robin-rykert.example.com", res.name
      assert_equal "default", res.namespace
    end

    test "it raises RecordNotFound when it fails" do
      Fog.mock!
      compute_resource = FactoryBot.build(:compute_resource_kubevirt)
      assert_raises ActiveRecord::RecordNotFound do
        compute_resource.find_vm_by_uuid("not_found.example.com")
      end
    end
  end

  test "test_connection should fail if client does not support virt" do
    client = stub
    client.stubs(:virt_supported?).returns(false)
    client.stubs(:valid?).returns(true)
    record = new_kubevirt_vcr
    record.stubs(:client).returns(client)
    assert_not record.test_connection
  end

  test "Verify client raises StandardError exception" do
    record = new_kubevirt_vcr
    record.stubs(:client).raises(StandardError.new('test'))
    record.test_connection
    assert_equal ['test'], record.errors[:base]
  end

  test "Verify client raises FingerprintException exception" do
    record = new_kubevirt_vcr
    record.stubs(:client).raises(Foreman::FingerprintException.new('test'))
    record.test_connection
    assert_includes record.errors[:base][0], "[Foreman::FingerprintException]: test"
  end
end

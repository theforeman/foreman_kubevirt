require 'test_plugin_helper'

class ForemanKubevirtTest < ActiveSupport::TestCase
  setup do
    User.current = User.find_by login: 'admin'
  end

  def new_kubevirt_vcr
    ::FactoryBot.build(:compute_resource_kubevirt)
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

  describe "networks" do
    test "returns list of networksattachmentdefs" do
      Fog.mock!
      compute_resource = FactoryBot.build(:compute_resource_kubevirt)
      res = compute_resource.networks
      assert_equal 1, res.count
      assert_equal '0e35b868-2464-11e9-93b4-525400c5a686', res.first.uid
    end

    test "in case of exception, returns an empty array" do
      compute_resource = FactoryBot.build(:compute_resource_kubevirt)
      client = stub
      compute_resource.stubs(:client).returns(client)
      client.stubs(:networkattachmentdefs).raises("exception")
      res = compute_resource.networks
      assert_equal 0, res.count
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

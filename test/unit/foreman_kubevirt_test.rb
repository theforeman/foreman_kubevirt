require 'test_plugin_helper'

class ForemanKubevirtTest < ActiveSupport::TestCase
  setup do
    User.current = User.find_by login: 'admin'
  end

  def new_kubevirt_vcr
    ::FactoryBot.build(:compute_resource_kubevirt)
    ComputeResource.new_provider(
      :provider => "Kubevirt",
      :name => 'kubevirt-multus',
      :hostname => "192.168.111.13",
      :api_port => "6443",
      :namespace => "default",
      :token => "kubetoken"
    )
  end

  require 'kubeclient'

  test "create_vm network based" do
    vm_args ={"cpu_cores"=>"1", "memory"=>"1073741824", "start"=>"1", "volumes_attributes"=>{"1554559479978"=>{"_delete"=>"", "storage_class"=>"local-storage", "capacity"=>"1", "bootable"=>"true"}, "1554559483803"=>{"_delete"=>"", "storage_class"=>"local-storage", "capacity"=>"2"}}, "name"=>"robin-rykert.example.com", "provision_method"=>"build", "firmware_type"=>:bios, "interfaces_attributes"=>{"0"=>{"cni_provider"=>"multus", "network"=>"ovs-foreman", "ip"=>"192.168.111.193", "mac"=>"a2:b4:a2:b6:a2:a8", "provision"=>true}}}
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    server = compute_resource.create_vm(vm_args)

    assert_equal "robin-rykert.example.com", server.name
    assert_equal 2, server.volumes.count
    assert_equal 2, server.disks.count
    assert_equal 1, server.interfaces.count
  end

  test "create_vm image based" do
    vm_args = {"cpu_cores"=>"1", "memory"=>"1073741824", "start"=>"1", "volumes_attributes"=>{"1554649143334"=>{"_delete"=>"", "storage_class"=>"local-storage", "capacity"=>"1", "bootable"=>"true"}}, "image_id"=>"kubevirt/fedora-cloud-registry-disk-demo", "name"=>"olive-kempter.example.com", "provision_method"=>"image", "firmware_type"=>:bios, "interfaces_attributes"=>{"0"=>{"cni_provider"=>"multus", "network"=>"ovs-foreman", "ip"=>"192.168.111.184", "mac"=>"a2:a4:a2:b2:a2:b6", "provision"=>true}}}
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    server = compute_resource.create_vm(vm_args)

    assert_equal "olive-kempter.example.com", server.name
    assert_equal 2, server.volumes.count
    assert_equal 2, server.disks.count
    assert_equal 1, server.interfaces.count
  end
end

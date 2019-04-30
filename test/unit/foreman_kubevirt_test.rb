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

  NETWORK_BASED_VM_ARGS = {
    "cpu_cores" => "1",
    "memory" => "1073741824",
    "start" => "1",
    "volumes_attributes" => {
      "0" => { "_delete" => "", "storage_class" => "local-storage", "capacity" => "1", "bootable" => "true" },
      "1" => { "_delete" => "", "storage_class" => "local-storage", "capacity" => "2" }
    },
    "name" => "robin-rykert.example.com",
    "provision_method" => "build",
    "firmware_type" => :bios,
    "interfaces_attributes" => {
      "0" => { "cni_provider" => "multus", "network" => "ovs-foreman", "ip" => "192.168.111.193", "mac" => "a2:b4:a2:b6:a2:a8", "provision" => true }
    }
  }.freeze

  IMAGE_BASED_VM_ARGS = {
    "cpu_cores" => "1",
    "memory" => "1073741824",
    "start" => "1",
    "volumes_attributes" => {
      "0" => { "_delete" => "", "storage_class" => "local-storage", "capacity" => "1", "bootable" => "false" }
    },
    "image_id" => "kubevirt/fedora-cloud-registry-disk-demo",
    "name" => "olive-kempter.example.com",
    "provision_method" => "image",
    "firmware_type" => :bios,
    "interfaces_attributes" => {
      "0" => { "cni_provider" => "multus", "network" => "ovs-foreman", "ip" => "192.168.111.184", "mac" => "a2:a4:a2:b2:a2:b6", "provision" => true }
    }
  }.freeze

  test "create_vm network based should pass" do
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    server = compute_resource.create_vm(NETWORK_BASED_VM_ARGS)

    assert_equal "robin-rykert.example.com", server.name
    assert_equal 2, server.volumes.count
    assert_equal 2, server.disks.count
    assert_equal 1, server.interfaces.count
  end

  test "create_vm image based should pass" do
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    server = compute_resource.create_vm(IMAGE_BASED_VM_ARGS)

    assert_equal "olive-kempter.example.com", server.name
    assert_equal 2, server.volumes.count
    assert_equal 2, server.disks.count
    assert_equal 1, server.interfaces.count
  end

  test "should fail when creating a VM with_bootable flag and image based" do
    vm_args = IMAGE_BASED_VM_ARGS.deep_dup
    vm_args["volumes_attributes"]["0"]["bootable"] = "true"
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    assert_raise(Foreman::Exception) do
      compute_resource.create_vm(vm_args)
    end
  end

  test "should fail when creating a VM without an image or pvc" do
    vm_args = IMAGE_BASED_VM_ARGS.deep_dup
    vm_args["image_id"] = nil
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    assert_raise(Foreman::Exception) do
      compute_resource.create_vm(vm_args)
    end
  end

  test "should fail when creating image-based VM without an image" do
    vm_args = IMAGE_BASED_VM_ARGS.deep_dup
    vm_args["volumes_attributes"] = {}
    vm_args["image_id"] = nil
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    assert_raise(Foreman::Exception) do
      compute_resource.create_vm(vm_args)
    end
  end

  test "should fail when creating a VM with PVC and not providing a capacity" do
    vm_args = NETWORK_BASED_VM_ARGS.deep_dup
    vm_args["volumes_attributes"]["0"]["capacity"] = nil
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    assert_raise(Foreman::Exception) do
      compute_resource.create_vm(vm_args)
    end
  end

  test "should fail when creating a VM with two bootable PVCs" do
    vm_args = NETWORK_BASED_VM_ARGS.deep_dup
    vm_args["volumes_attributes"]["0"]["bootable"] = "true"
    vm_args["volumes_attributes"]["1"]["bootable"] = "true"
    Fog.mock!
    compute_resource = new_kubevirt_vcr
    assert_raise(Foreman::Exception) do
      compute_resource.create_vm(vm_args)
    end
  end
end

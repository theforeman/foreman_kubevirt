require 'test_plugin_helper'

class ForemanKubevirtTest < ActiveSupport::TestCase
  setup do
    User.current = User.find_by login: 'admin'
  end

  def new_kubevirt_vcr
    ComputeResource.new_provider(
      :provider => "Kubevirt",
      :name => 'kubevirt-multus',
      :hostname => "192.168.111.13",
      :api_port => "6443",
      :namespace => "default",
      :token => "kubetoken"
    )
  end

  test "host_interfaces_attrs" do
    record = new_kubevirt_vcr
    host = FactoryBot.build(:host_kubevirt, :with_interfaces)
    result = record.host_interfaces_attrs(host)
    expected_res = {"0" => {"cni_provider" => "multus",
                          "network" => "ovs-foreman",
                          :ip => "192.168.111.200",
                          :mac => "a2:b4:a2:b2:a2:a8",
                          :provision => true}}
    assert_equal expected_res, result
  end
end

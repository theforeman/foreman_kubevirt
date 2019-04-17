FactoryBot.define do
  factory :nic_kubevirt, class: 'Nic::Managed' do
    mac "a2:b4:a2:b2:a2:a8"
    ip "192.168.111.200"
    type "Nic::Managed"
    name "elton-kniola.example.com"
    host_id 1
    subnet_id 2
    domain_id 1
    attrs {}
    created_at nil
    updated_at nil
    provider nil
    username nil
    password nil
    virtual false
    link true
    identifier ""
    tag ""
    attached_to ""
    managed true
    mode "balance-rr"
    attached_devices ""
    bond_options ""
    primary true
    provision true
    compute_attributes { { "cni_provider" => "multus", "network" => "ovs-foreman" } }
    ip6 ""
    subnet6_id nil
  end
end

FactoryBot.define do
  factory :compute_resource_kubevirt, class: 'ForemanKubevirt::Kubevirt' do
      provider "Kubevirt"
      name 'kubevirt-multus'
      hostname "192.168.111.13"
      api_port "6443"
      namespace "default"
      token "kubetoken"
  end
end

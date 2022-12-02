FactoryBot.define do
  factory :host_kubevirt, class: 'Host::Managed' do
    name { "susie-baynham.example.com" }
    last_compile { nil }
    last_report { nil }
    updated_at { nil }
    root_pass { "$5$pzp5IoYXH9WQT6Ks$fk1OzfJAK1" }
    architecture_id { 1 }
    operatingsystem_id { 3 }
    ptable_id { 91 }
    medium_id { 13 }
    build { true }
    comment { "" }
    disk { "" }
    installed_at { nil }
    model_id { nil }
    hostgroup_id { 31 }
    owner_id { 4 }
    owner_type { "User" }
    enabled { true }
    puppet_ca_proxy_id { nil }
    managed { true }
    use_image { nil }
    image_file { nil }
    uuid { nil }
    compute_resource_id { 7 }
    puppet_proxy_id { 1 }
    certname { nil }
    image_id { nil }
    organization_id { 2 }
    location_id { 1 }
    type { "Host::Managed" }
    otp { nil }
    realm_id { nil }
    compute_profile_id { nil }
    provision_method { "build" }
    grub_pass { "$6$aRZAzZm1TOa5WAGX$.Cwxy5zCrjVQqHUE/0Ic9oQ" }
    global_status { 0 }
    lookup_value_matcher { "fqdn=susie-baynham.example.com" }
    pxe_loader { "PXELinux BIOS" }
    initiated_at { nil }
    build_errors { nil }

    trait :with_interfaces do
      interfaces { build_list :nic_kubevirt, 1 }
    end
  end
end

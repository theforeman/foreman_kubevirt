providerSpecificNICInfo = function(form) {
  cni_provider = form.find('select.kubevirt-cni-provider :selected').text();
  if (cni_provider === 'pod') {
    network = '';
  } else {
    network = form.find('select.kubevirt-network').val();
  }
  return network + ' @ ' + cni_provider;
}

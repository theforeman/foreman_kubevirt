providerSpecificNICInfo = function(form) {
  return form.find('select.kubevirt_network').val() + ' @ ' + form.find('select.kubevirt_cni_provider :selected').text();
}

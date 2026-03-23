$(document).ajaxComplete(function() {
  kubevirtVerifyTls();
});

$(document).on('ContentLoad', function() {
  kubevirtVerifyTls();
});

function kubevirtVerifyTls() {
  const verify_tls = $('#verify_tls');
  const field = $('#compute_resource_ca_cert');

  switch (verify_tls.val()) {
    case 'system':
      field.prop('disabled', true);
      field.attr('placeholder', __('System CA will be used for the connection'));
      field.attr('required', false);
      break;
    case 'disable':
      field.prop('disabled', true);
      field.attr('placeholder', __('TLS will be disabled for the connection'));
      field.attr('required', false);
      break;
    case 'custom':
      field.prop('disabled', false);
      field.attr('placeholder', __('Provide a CA, or a correctly ordered CA chain or a path to a file.'));
      field.attr('required', true);
      break;
  }
}

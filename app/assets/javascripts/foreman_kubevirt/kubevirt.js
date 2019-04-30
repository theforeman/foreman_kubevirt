bootableRadio = function (item) {
  disabled = $('[id$=_bootable_true]:disabled:checked:visible');

  $('[id$=_bootable_true]').prop('checked', false);
  if (disabled.length > 0) {
    disabled.prop('checked', true);
  } else {
    $(item).prop('checked', true);
  }
}

cniProviderSelected = function (item) {
  selected = $(item).val().toLowerCase();
  networks = $(item).parentsUntil('.fields').parent().find('#networks');

  if (selected == "pod") {
    disableDropdown(networks);
  } else {
    enableDropdown(networks);
  }
}

function disableDropdown(item) {
  item.hide();
  item.attr('disabled', true);
  $(item).closest('.removable-item').find('.kubevirt-network').prop('disabled', true);
}

function enableDropdown(item) {
  $(item).closest('.removable-item').find('.kubevirt-network').prop('disabled', false);
  item.attr('disabled', false);
  item.find(':input').attr('disabled', false);
  item.show();
}
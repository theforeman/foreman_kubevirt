bootableRadio = function (item) {
  const disabled = $('[id$=_bootable_true]:disabled:checked:visible');

  $('[id$=_bootable_true]').prop('checked', false);
  if (disabled.length > 0) {
    disabled.prop('checked', true);
  } else {
    $(item).prop('checked', true);
  }
}

cniProviderSelected = function (item) {
  const selected = $(item).val().toLowerCase();
  podSelected = selected == "pod";
  changeNetworkElementVisibility(!podSelected);
}

function changeNetworkElementVisibility(toggle) {
  if (toggle) {
    $('.kubevirt-network').parents('.form-group').css('display', '');
  } else {
    $('.kubevirt-network').parents('.form-group').css('display', 'none');
  }
}

function changeNetworkElementVisibilityOnLoad() {
  selected = $('select.kubevirt-cni-provider').val().toLowerCase();
  changeNetworkElementVisibility(selected != "pod");
}

$(document).ready(changeNetworkElementVisibilityOnLoad);

bootableRadio = function (item) {
  const disabled = $('[id$=_bootable_true]:disabled:checked:visible');

  $('[id$=_bootable_true]').prop('checked', false);
  if (disabled.length > 0) {
    disabled.prop('checked', true);
  } else {
    $(item).prop('checked', true);
  }
}
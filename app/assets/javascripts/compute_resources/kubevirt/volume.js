disableElement = function(element) {
  element.prop('disabled', true);
}

enableElement = function(element) {
  element.prop('disabled', false);
}

pvcSelected = function(element) {
  formMod = $(element).closest('.removable-item');
  pvcSelectedVolumeMod = formMod.find('.pvc-selected-volume');
  pvcSizeMod = formMod.find('.pvc-size');

  if(element.value === "") {
    enableElement(pvcSelectedVolumeMod);
    enableElement(pvcSizeMod);
    pvcSizeMod.val(null);
  } else {
    disableElement(pvcSelectedVolumeMod);
    disableElement(pvcSizeMod);
    var pvc = searchByName(element.value, element.options);
    if (pvc != null) {
      setPvcSize(pvc, pvcSizeMod);
    }
  }
}

searchByName = function (nameKey, elements){
  for (var i=0; i < elements.length; i++) {
    nameAttribute = elements[i].attributes["name"];
    if (nameAttribute != null && nameAttribute.value === nameKey) {
      return elements[i];
    }
  }
}

setPvcSize = function (pvc, pvcSizeMod) {
  pvcRequests = pvc.attributes["requests"].value;
  if (pvcRequests != null) {
    pvcStorageSize = pvcRequests.match(/"(.*?)"/)[1];
    pvcSizeMod.val(pvcStorageSize);
  } else {
    pvcSizeMod.val(null);
  }
}

bootableRadio = function (item) {
  const disabled = $('[id$=_bootable_true]:disabled:checked:visible');

  $('[id$=_bootable_true]').prop('checked', false);
  if (disabled.length > 0) {
    disabled.prop('checked', true);
  } else {
    $(item).prop('checked', true);
  }
}
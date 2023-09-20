function dragstart_handler(ev) {
  console.log("dragStart");
  var dti = ev.dataTransfer.items;
  if (dti === undefined || dti == null) {
    console.log("Browser does not support DataTransferItem interface");
    return;
  }

  // Add the id of the drag source element to the drag data payload so
  // it is available when the drop event is fired
  dti.add(ev.target.id, "text/plain");
  // Tell the browser both copy and move are possible
  ev.effectAllowed = "copy";
}

function dragover_handler(ev) {
    console.log("dragOver");
    var dti = ev.dataTransfer.items;
    if (dti === undefined || dti == null) {
        console.log("Browser does not support DataTransferItem interface");
        return;
    }
    // Change the target element's border to signify a drag over event
    // has occurred
    ev.currentTarget.style.background = "lightgray";
    ev.preventDefault();
}

function drop_handler(ev) {
    console.log("Drop");
    ev.preventDefault();
    var dti = ev.dataTransfer.items;
    if (dti === undefined || dti == null) {
        console.log("Browser does not support DataTransferItem interface");
        return;
    }
    // Get the id of the drag source element (that was added to the drag data
    // payload by the dragstart event handler). Even though only one drag item
    // was explicitly added, the browser may include other items so need to search
    // for the plain/text item.
    for (var i=0; i < dti.length; i++) {
        console.log("Drop: item[" + i + "].kind = " + dti[i].kind + " ; item[" + i + "].type = " + dti[i].type);
        if ((dti[i].kind == 'string') && (dti[i].type.match('^text/plain'))) {
          // This item is the target node
          dti[i].getAsString(function (id){
              // Copy the element
              var nodeCopy = document.getElementById(id).cloneNode(true);
              console.log("Copying " + nodeCopy);
              nodeCopy.id = "newId";
              ev.target.appendChild(nodeCopy);
          });
        }
    }

    // Clear background
    ev.currentTarget.style.background = "none";
}

function dragend_handler(ev) {
    console.log("dragEnd");
    var dti = ev.dataTransfer.items;
    if (dti === undefined || dti == null) {
        console.log("Browser does not support DataTransferItem interface");
        return;
    }

    // Remove all of the items from the list.
    dti.clear();
}

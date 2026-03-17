document.addEventListener("DOMContentLoaded", function () {
  function bindDragAndDrop() {
    const draggableItems = document.querySelectorAll(".draggable-var");
    const zones = document.querySelectorAll(".role-zone");

    draggableItems.forEach(function (item) {
      item.addEventListener("dragstart", function (event) {
        event.dataTransfer.setData("text/plain", JSON.stringify({
          var_name: item.dataset.varName,
          from_role: item.dataset.fromRole
        }));
      });
    });

    zones.forEach(function (zone) {
      zone.addEventListener("dragover", function (event) {
        event.preventDefault();
        zone.classList.add("is-over");
      });

      zone.addEventListener("dragleave", function () {
        zone.classList.remove("is-over");
      });

      zone.addEventListener("drop", function (event) {
        event.preventDefault();
        zone.classList.remove("is-over");
        const payload = JSON.parse(event.dataTransfer.getData("text/plain"));
        const toRole = zone.dataset.role;

        if (window.Shiny) {
          window.Shiny.setInputValue("role_drop", {
            var_name: payload.var_name,
            from_role: payload.from_role,
            to_role: toRole,
            nonce: Date.now()
          }, { priority: "event" });
        }
      });
    });
  }

  const observer = new MutationObserver(function () {
    bindDragAndDrop();
  });

  observer.observe(document.body, { childList: true, subtree: true });
  bindDragAndDrop();
});

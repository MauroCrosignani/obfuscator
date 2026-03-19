document.addEventListener("DOMContentLoaded", function () {
  function applyFilter() {
    const searchInput = document.getElementById("var_search");
    if (!searchInput) return;
    
    const query = searchInput.value.toLowerCase();
    document.querySelectorAll(".draggable-var").forEach(function (item) {
      const text = item.dataset.varName.toLowerCase();
      if (text.includes(query)) {
        item.classList.remove("hidden-var");
      } else {
        item.classList.add("hidden-var");
      }
    });
  }

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
    applyFilter();
  });

  const searchInput = document.getElementById("var_search");
  if (searchInput) {
    searchInput.addEventListener("input", applyFilter);
  }

  observer.observe(document.body, { childList: true, subtree: true });
  bindDragAndDrop();
});

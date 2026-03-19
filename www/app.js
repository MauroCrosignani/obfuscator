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

  // --- Logica de Editor de Jerarquias ---
  
  window.initHierarchySortable = function() {
    const sourceList = document.getElementById("hierarchy-source-list");
    const destList = document.getElementById("hierarchy-dest-list");
    if (!sourceList || !destList) return;

    // Inicializar lista de origen
    new Sortable(sourceList, {
      group: 'hierarchy',
      animation: 150,
      onEnd: updateHierarchyState
    });

    // Inicializar contenedores de carpetas existentes
    document.querySelectorAll(".folder-content").forEach(el => {
      initFolderSortable(el);
    });

    setupHierarchyInteractions();
  };

  function initFolderSortable(el) {
    new Sortable(el, {
      group: 'hierarchy',
      animation: 150,
      onEnd: updateHierarchyState,
      onAdd: updateHierarchyState
    });
  }

  function setupHierarchyInteractions() {
    const container = document.querySelector(".hierarchy-editor-container");
    if (!container) return;

    // Multiseleccion por click
    container.addEventListener("click", function(e) {
      const item = e.target.closest(".hierarchy-item");
      if (item) {
        item.classList.toggle("selected");
        updateSelectionBar();
      }

      if (e.target.closest("#add_hierarchy_group")) {
        createNewGroup();
      }

      if (e.target.closest("#group_selected")) {
        groupSelectedItems();
      }
    });
  }

  function updateSelectionBar() {
    const selected = document.querySelectorAll(".hierarchy-item.selected");
    const bar = document.getElementById("hierarchy-selection-bar");
    const countLabel = document.getElementById("hierarchy-selection-count");
    
    if (selected.length > 0) {
      bar.style.display = "flex";
      countLabel.textContent = selected.length + " seleccionado(s)";
    } else {
      bar.style.display = "none";
    }
  }

  function createNewGroup(name) {
    const groupName = name || prompt("Nombre del nuevo grupo:");
    if (!groupName) return;

    const destList = document.getElementById("hierarchy-dest-list");
    const folder = document.createElement("div");
    folder.className = "hierarchy-folder";
    folder.dataset.group = groupName;
    folder.innerHTML = `
      <div class="folder-header"><i class="fas fa-folder-open"></i> ${groupName}</div>
      <div class="folder-content"></div>
    `;
    destList.appendChild(folder);
    initFolderSortable(folder.querySelector(".folder-content"));
    updateHierarchyState();
  }

  function groupSelectedItems() {
    const selected = document.querySelectorAll(".hierarchy-item.selected");
    if (selected.length === 0) return;

    const groupName = prompt("¿Bajo qué nombre agrupar estos " + selected.length + " items?");
    if (!groupName) return;

    // Crear carpeta si no existe (o simplemente crear una nueva siempre con ese nombre)
    createNewGroup(groupName);
    const lastFolder = document.querySelector(`.hierarchy-folder[data-group="${groupName}"]:last-child .folder-content`);
    
    selected.forEach(item => {
      item.classList.remove("selected");
      lastFolder.appendChild(item);
    });

    updateSelectionBar();
    updateHierarchyState();
  }

  function updateHierarchyState() {
    if (!window.Shiny) return;

    const mapping = {};
    document.querySelectorAll(".hierarchy-folder").forEach(folder => {
      const groupName = folder.dataset.group;
      const items = Array.from(folder.querySelectorAll(".hierarchy-item")).map(i => i.dataset.value);
      if (items.length > 0) {
        mapping[groupName] = items;
      }
    });

    window.Shiny.setInputValue("hierarchy_tree_state", mapping);
  }
});

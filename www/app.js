document.addEventListener("DOMContentLoaded", function () {
  function safeLocalStorageGet(key, fallbackValue) {
    try {
      return localStorage.getItem(key) || fallbackValue;
    } catch (error) {
      return fallbackValue;
    }
  }

  function safeLocalStorageSet(key, value) {
    try {
      localStorage.setItem(key, value);
      return true;
    } catch (error) {
      return false;
    }
  }

  function applyFilter() {
    const searchInput = document.getElementById("var_search");
    if (!searchInput) return;

    const query = searchInput.value.toLowerCase();
    document.querySelectorAll(".draggable-var").forEach(function (item) {
      const text = (item.dataset.varName || "").toLowerCase();
      item.classList.toggle("hidden-var", !text.includes(query));
    });
  }

  function initTheme() {
    const savedTheme = safeLocalStorageGet("obfuscator-theme", "light");
    document.body.classList.toggle("dark-theme", savedTheme === "dark");
    updateThemeIcon(savedTheme);
  }

  function updateThemeIcon(theme) {
    const label = document.querySelector("#theme-toggle .theme-label");
    if (!label) return;
    const nextValue = theme === "dark" ? "OS" : "CL";
    if (label.textContent !== nextValue) {
      label.textContent = nextValue;
    }
  }

  window.toggleTheme = function () {
    const isDark = document.body.classList.toggle("dark-theme");
    const newTheme = isDark ? "dark" : "light";
    safeLocalStorageSet("obfuscator-theme", newTheme);
    updateThemeIcon(newTheme);
  };

  function bindDragAndDrop() {
    const draggableItems = document.querySelectorAll(".draggable-var");
    const zones = document.querySelectorAll(".role-zone");

    draggableItems.forEach(function (item) {
      if (item.dataset.dragBound === "true") return;
      item.dataset.dragBound = "true";

      item.addEventListener("dragstart", function (event) {
        item.classList.add("dragging");
        event.dataTransfer.setData("text/plain", JSON.stringify({
          var_name: item.dataset.varName,
          from_role: item.dataset.fromRole
        }));
      });

      item.addEventListener("dragend", function () {
        item.classList.remove("dragging");
      });
    });

    zones.forEach(function (zone) {
      if (zone.dataset.dropBound === "true") return;
      zone.dataset.dropBound = "true";

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

  function updateSelectionBar() {
    const selected = document.querySelectorAll(".hierarchy-item.selected");
    const bar = document.getElementById("hierarchy-selection-bar");
    const countLabel = document.getElementById("hierarchy-selection-count");
    if (!bar || !countLabel) return;

    if (selected.length > 0) {
      bar.style.display = "flex";
      countLabel.textContent = selected.length + " seleccionado(s)";
    } else {
      bar.style.display = "none";
    }
  }

  function hierarchyDropTargets() {
    const targets = [];
    const sourceList = document.getElementById("hierarchy-source-list");
    if (sourceList) targets.push(sourceList);

    document.querySelectorAll(".folder-content").forEach(function (el) {
      targets.push(el);
    });

    return targets;
  }

  function bindHierarchyItem(item) {
    if (!item || item.dataset.hierarchyBound === "true") return;
    item.dataset.hierarchyBound = "true";
    item.setAttribute("draggable", "true");

    item.addEventListener("dragstart", function (event) {
      item.classList.add("dragging");
      event.dataTransfer.effectAllowed = "move";
      event.dataTransfer.setData("text/plain", item.dataset.value || "");
    });

    item.addEventListener("dragend", function () {
      item.classList.remove("dragging");
    });
  }

  function bindHierarchyDropTarget(target) {
    if (!target || target.dataset.hierarchyDropBound === "true") return;
    target.dataset.hierarchyDropBound = "true";

    target.addEventListener("dragover", function (event) {
      event.preventDefault();
      target.classList.add("is-over");
    });

    target.addEventListener("dragleave", function () {
      target.classList.remove("is-over");
    });

    target.addEventListener("drop", function (event) {
      event.preventDefault();
      target.classList.remove("is-over");
      const dragged = document.querySelector(".hierarchy-item.dragging");
      if (!dragged) return;
      target.appendChild(dragged);
      dragged.classList.remove("selected");
      updateSelectionBar();
      updateHierarchyState();
    });
  }

  function syncHierarchySourceList() {
    const sourceList = document.getElementById("hierarchy-source-list");
    if (!sourceList) return;

    const groupedValues = new Set();
    document.querySelectorAll(".folder-content .hierarchy-item").forEach(function (item) {
      groupedValues.add(item.dataset.value);
    });

    sourceList.querySelectorAll(".hierarchy-item").forEach(function (item) {
      if (groupedValues.has(item.dataset.value)) {
        item.remove();
      }
    });
  }

  function refreshHierarchyBindings() {
    document.querySelectorAll(".hierarchy-item").forEach(bindHierarchyItem);
    hierarchyDropTargets().forEach(bindHierarchyDropTarget);
  }

  function createFolderElement(groupName) {
    const folder = document.createElement("div");
    folder.className = "hierarchy-folder";
    folder.dataset.group = groupName;
    folder.innerHTML = [
      '<div class="folder-header">',
      '<span class="studio-icon studio-icon-folder" title="Grupo" aria-label="Grupo">G</span>',
      groupName,
      "</div>",
      '<div class="folder-content"></div>'
    ].join("");
    return folder;
  }

  function createNewGroup(name) {
    const groupName = name || prompt("Nombre del nuevo grupo:");
    if (!groupName) return null;

    const destList = document.getElementById("hierarchy-dest-list");
    if (!destList) return null;

    const folder = createFolderElement(groupName);
    destList.appendChild(folder);
    refreshHierarchyBindings();
    updateHierarchyState();
    return folder;
  }

  function groupSelectedItems() {
    const selected = Array.from(document.querySelectorAll(".hierarchy-item.selected"));
    if (selected.length === 0) return;

    const groupName = prompt("Bajo que nombre agrupar estos " + selected.length + " items?");
    if (!groupName) return;

    const folder = createNewGroup(groupName);
    if (!folder) return;

    const destination = folder.querySelector(".folder-content");
    selected.forEach(function (item) {
      item.classList.remove("selected");
      destination.appendChild(item);
    });

    updateSelectionBar();
    updateHierarchyState();
  }

  function setupHierarchyInteractions() {
    const container = document.querySelector(".hierarchy-editor-container");
    if (!container || container.dataset.interactionsBound === "true") return;
    container.dataset.interactionsBound = "true";

    container.addEventListener("click", function (event) {
      const item = event.target.closest(".hierarchy-item");
      if (item) {
        item.classList.toggle("selected");
        updateSelectionBar();
        return;
      }

      if (event.target.closest("#add_hierarchy_group")) {
        createNewGroup();
        return;
      }

      if (event.target.closest("#group_selected")) {
        groupSelectedItems();
      }
    });
  }

  function updateHierarchyState() {
    if (!window.Shiny) return;

    const mapping = {};
    document.querySelectorAll(".hierarchy-folder").forEach(function (folder) {
      const groupName = folder.dataset.group;
      const items = Array.from(folder.querySelectorAll(".folder-content .hierarchy-item")).map(function (item) {
        return item.dataset.value;
      });
      if (items.length > 0) {
        mapping[groupName] = items;
      }
    });

    window.Shiny.setInputValue("hierarchy_tree_state", mapping, { priority: "event" });
  }

  window.initHierarchySortable = function () {
    syncHierarchySourceList();
    refreshHierarchyBindings();
    setupHierarchyInteractions();
    updateSelectionBar();
    updateHierarchyState();
  };

  function flashCopyState(btn, text, stateClass) {
    if (!btn) return;

    const originalHtml = btn.dataset.originalHtml || btn.innerHTML;
    btn.dataset.originalHtml = originalHtml;
    btn.innerHTML = text;
    btn.classList.remove("success", "manual-copy");
    if (stateClass) {
      btn.classList.add(stateClass);
    }

    if (stateClass === "manual-copy") {
      return;
    }

    window.setTimeout(function () {
      btn.innerHTML = originalHtml;
      btn.classList.remove("success", "manual-copy");
    }, 2000);
  }

  function selectCodeBlock(codeElement) {
    const selection = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(codeElement);
    selection.removeAllRanges();
    selection.addRange(range);
  }

  function fallbackCopy(codeElement, btn) {
    selectCodeBlock(codeElement);

    let copied = false;
    try {
      copied = document.execCommand("copy");
    } catch (error) {
      copied = false;
    }

    if (copied) {
      flashCopyState(btn, '<span class="studio-icon studio-icon-check">OK</span> Copiado', "success");
    } else {
      flashCopyState(btn, "Selecciona y copia manualmente", "manual-copy");
    }
  }

  window.copyRCodeToClipboard = function () {
    const codeElement = document.querySelector(".code-container pre");
    const btn = document.querySelector(".copy-code-btn");
    if (!codeElement || !btn) return;

    const code = codeElement.innerText;
    if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
      navigator.clipboard.writeText(code).then(function () {
        flashCopyState(btn, '<span class="studio-icon studio-icon-check">OK</span> Copiado', "success");
      }).catch(function () {
        fallbackCopy(codeElement, btn);
      });
    } else {
      fallbackCopy(codeElement, btn);
    }
  };

  initTheme();
  bindDragAndDrop();
  applyFilter();

  const observer = new MutationObserver(function () {
    bindDragAndDrop();
    applyFilter();
  });

  const searchInput = document.getElementById("var_search");
  if (searchInput) {
    searchInput.addEventListener("input", applyFilter);
  }

  observer.observe(document.body, { childList: true, subtree: true });
});

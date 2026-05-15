local M = {}

local function deep_copy(value)
  return vim.deepcopy(value)
end

local function command_key(command)
  return table.concat(command.path or {}, "\0")
end

local function source_file_for_command(source_cmd)
  return source_cmd.source_file
end

local function add_unique(list, value)
  for _, existing in ipairs(list) do
    if existing == value then
      return
    end
  end
  table.insert(list, value)
end

local function handler_path_from_command(command)
  if not command.path or #command.path == 0 then
    return "root"
  end
  return table.concat(command.path, ".")
end

local function child_ids_for_file(file_projection)
  local children = {}
  for _, entity in ipairs(file_projection.entities or {}) do
    if entity.kind ~= "source_file" then
      table.insert(children, entity.id)
    end
  end
  return children
end

local function emit_duplicate(diagnostics, selector_id)
  table.insert(diagnostics, {
    source = "bashly_join",
    code = "SELECTOR_DUPLICATE",
    severity = "error",
    message = "Selector emitted by more than one projection producer.",
    selector = selector_id,
  })
end

local function selector_producer(seen_producers, diagnostics, selector_id, producer)
  if seen_producers[selector_id] and seen_producers[selector_id] ~= producer then
    emit_duplicate(diagnostics, selector_id)
    return
  end
  seen_producers[selector_id] = producer
end

function M.join(graph_projection, source_projection)
  local joined = {
    schema_version = 1,
    workspace = graph_projection.workspace,
    bashly = deep_copy(graph_projection.bashly),
    source = deep_copy(source_projection.source),
    selectors = {},
    diagnostics = {},
  }

  local selectors_map = {}
  local diagnostics = deep_copy(graph_projection.diagnostics or {})
  for _, diagnostic in ipairs(source_projection.diagnostics or {}) do
    table.insert(diagnostics, deep_copy(diagnostic))
  end
  local source_handlers = {}
  local seen_producers = {}

  for selector_id, selector in pairs(source_projection.selectors or {}) do
    selector_producer(seen_producers, diagnostics, selector_id, "source")
    if selectors_map[selector_id] then
      emit_duplicate(diagnostics, selector_id)
    else
      selectors_map[selector_id] = deep_copy(selector)
    end
    if selector_id:match("^source%.handler%.") then
      source_handlers[selector_id] = true
    end
  end

  for _, command in ipairs(joined.bashly.commands or {}) do
    selector_producer(seen_producers, diagnostics, command.id, "graph")
  end

  for selector_id, selector in pairs(graph_projection.selectors or {}) do
    selector_producer(seen_producers, diagnostics, selector_id, "graph")
    if selectors_map[selector_id] then
      emit_duplicate(diagnostics, selector_id)
    else
      selectors_map[selector_id] = deep_copy(selector)
    end
  end

  for _, command in ipairs(joined.bashly.commands or {}) do
    local handler_id = "source.handler." .. handler_path_from_command(command)
    local source_file = source_file_for_command(command)
    local file_selector_id = "source.file." .. source_file

    if selectors_map[file_selector_id] then
      local file_selector = selectors_map[file_selector_id]
      file_selector.children = child_ids_for_file(source_projection.source.files[source_file] or {})
      add_unique(file_selector.children, handler_id)
      add_unique(file_selector.children, "source.command." .. handler_path_from_command(command) .. ".whole_file")
    end

    if source_projection.source.files[source_file] and source_handlers[handler_id] then
      local command_selector = selectors_map[command.id]
      local handler_selector = selectors_map[handler_id]
      command.handler_selector = handler_id

      command_selector.children = command_selector.children or {}
      add_unique(command_selector.children, handler_id)

      handler_selector.parent = file_selector_id
      handler_selector.children = handler_selector.children or {}
      add_unique(handler_selector.children, command.id)
    else
      table.insert(diagnostics, {
        source = "bashly_join",
        code = "BASHLY_HANDLER_MISSING",
        severity = "error",
        message = "Expected source handler selector was not found for command.",
        selector = command.id,
        path = source_file,
      })
    end
  end

  local owned_handlers = {}
  for _, command in ipairs(joined.bashly.commands or {}) do
    if command.handler_selector then
      owned_handlers[command.handler_selector] = true
    end
  end

  for selector_id, selector in pairs(selectors_map) do
    if selector_id:match("^source%.handler%.") and not owned_handlers[selector_id] then
      table.insert(diagnostics, {
        source = "bashly_join",
        code = "SOURCE_HANDLER_ORPHANED",
        severity = "warning",
        message = "Source handler exists but no Bashly command owns it.",
        selector = selector_id,
        path = selector.path,
      })
    end
  end

  for _, command in ipairs(joined.bashly.commands or {}) do
    command.args = command.args or {}
    command.flags = command.flags or {}
    command.env = command.env or {}
  end

  joined.selectors = selectors_map
  joined.diagnostics = diagnostics
  return joined
end

return M

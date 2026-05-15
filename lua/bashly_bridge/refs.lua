local M = {}

local function command_path_string(command)
  if not command.path or #command.path == 0 then
    return "root"
  end
  return table.concat(command.path, ".")
end

local function target_selector_for_key(command, key)
  local command_path = command_path_string(command)
  if key:sub(1, 2) == "--" then
    return string.format("bashly.flag.%s.%s", command_path, key)
  end
  return string.format("bashly.arg.%s.%s", command_path, key)
end

local function declared_targets(command)
  local targets = {}
  for _, selector_id in ipairs(command.args or {}) do
    targets[selector_id] = true
  end
  for _, selector_id in ipairs(command.flags or {}) do
    targets[selector_id] = true
  end
  return targets
end

local function source_range_from_match(line_index, start_col, end_col)
  return {
    start_line = line_index,
    start_column = start_col,
    end_line = line_index,
    end_column = end_col,
  }
end

local function scan_buffer_for_args_refs(bufnr, command)
  local refs = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local source_selector = command.handler_selector or string.format(
    "source.handler.%s",
    command_path_string(command)
  )

  for line_index, line in ipairs(lines) do
    local search_start = 1
    while true do
      local start_idx = line:find("${args[", search_start, true)
      if not start_idx then
        break
      end

      local close_brace = line:find("}", start_idx + 8, true)
      local close_bracket = line:find("]", start_idx + 8, true)
      if not close_brace or not close_bracket or close_bracket > close_brace then
        search_start = start_idx + 1
      else
        local key = line:sub(start_idx + 7, close_bracket - 1)
        local target_selector = target_selector_for_key(command, key)
        table.insert(refs, {
          kind = "bashly_args_ref",
          key = key,
          source_selector = source_selector,
          target_selector = target_selector,
          path = vim.api.nvim_buf_get_name(bufnr),
          range = source_range_from_match(line_index - 1, start_idx - 1, close_brace),
        })
        search_start = close_brace + 1
      end
    end
  end

  return refs
end

function M.extract_bashly_args_refs(bufnr, command)
  return scan_buffer_for_args_refs(bufnr, command)
end

function M.resolve_bashly_args_ref(ref, command)
  local target_selector = target_selector_for_key(command, ref.key)
  local declared = declared_targets(command)
  if declared[target_selector] then
    return target_selector
  end
  return nil
end

function M.diagnostics_for_command(command, refs)
  local diagnostics = {}
  local seen_targets = {}
  local declared = declared_targets(command)
  local source_selector = command.handler_selector or string.format(
    "source.handler.%s",
    command_path_string(command)
  )
  local path = command.source_file

  for _, ref in ipairs(refs) do
    local resolved = M.resolve_bashly_args_ref(ref, command)
    if resolved then
      ref.target_selector = resolved
      seen_targets[resolved] = true
    else
      ref.target_selector = nil
      table.insert(diagnostics, {
        source = "bashly-projector",
        code = "BASHLY_ARGS_REF_UNKNOWN",
        severity = "error",
        message = string.format("%s is used by command %s but is not declared in bashly.yml", ref.key, command.name),
        selector = source_selector,
        path = path,
        range = ref.range,
      })
    end
  end

  for selector_id in pairs(declared) do
    if not seen_targets[selector_id] then
      local is_flag = selector_id:match("^bashly%.flag%.") ~= nil
      table.insert(diagnostics, {
        source = "bashly-projector",
        code = is_flag and "BASHLY_FLAG_DECLARED_UNUSED" or "BASHLY_ARG_DECLARED_UNUSED",
        severity = "warning",
        message = string.format("%s is declared by command %s but is not used in its handler", selector_id, command.name),
        selector = source_selector,
        path = path,
      })
    end
  end

  return diagnostics
end

return M

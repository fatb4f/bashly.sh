local selectors = require("bashly_bridge.selectors")

local M = {}

local annotation_kinds = {
  cmd = true,
  arg = true,
  option = true,
  flag = true,
  env = true,
}

local ref_annotation_kinds = {
  arg = true,
  option = true,
  flag = true,
  env = true,
}

local function file_stem(relpath)
  local stem = (relpath or ""):gsub("^.*/", "")
  stem = stem:gsub("%.sh$", "")
  stem = stem:gsub("_command$", "")
  return stem
end

local function handler_name(relpath)
  local stem = file_stem(relpath)
  stem = stem:gsub("_", ".")
  if stem == "" or stem == "root" then
    return "root"
  end
  return stem
end

local function range_from_span(line_index, start_idx, end_idx)
  return {
    start_line = line_index,
    start_column = start_idx - 1,
    end_line = line_index,
    end_column = end_idx,
  }
end

local function fact_selector(kind, relpath, name, line_index, start_idx)
  return selectors.argc_fact(kind, file_stem(relpath), name, line_index, start_idx - 1)
end

local function ref_selector(relpath, name, line_index, start_idx)
  return selectors.argc_ref(file_stem(relpath), name, line_index, start_idx - 1)
end

local function annotation_selector(kind, relpath, name, line_index, start_idx)
  return selectors.argc_annotation(file_stem(relpath), kind, name, line_index, start_idx - 1)
end

local function command_lookup(projection)
  local owned = {}
  local commands = (projection and projection.bashly and projection.bashly.commands) or {}
  for _, command in ipairs(commands) do
    if command.source_file then
      owned[command.source_file] = true
    end
  end
  return owned
end

local function scan_annotations(lines, relpath, owned_file, selectors_out, diagnostics_out)
  local facts = {}
  local facts_by_name = {}
  local has_argc_usage = false
  local source_handler = selectors.handler(handler_name(relpath))
  local selector_map = selectors_out
  local owned = owned_file[relpath] == true

  for line_index, line in ipairs(lines) do
    for kind in pairs(annotation_kinds) do
      local start_idx, end_idx, name = line:find("@" .. kind .. "%s+([%w_%-]+)")
      if start_idx and end_idx and name then
        has_argc_usage = true
        local selector_id = annotation_selector(kind, relpath, name, line_index - 1, start_idx)
        local fact = {
          kind = kind,
          name = name,
          source_file = relpath,
          range = range_from_span(line_index - 1, start_idx, end_idx),
          selector = selector_id,
        }
        table.insert(facts, fact)
        if not facts_by_name[name] then
          facts_by_name[name] = fact
        end
        selector_map[selector_id] = {
          id = selector_id,
          kind = "argc_fact",
          path = relpath,
          range = fact.range,
          parent = nil,
          children = {},
        }
      end
    end
  end

  if owned and has_argc_usage then
    table.insert(diagnostics_out, {
      source = "bashly-projector",
      code = "ARGC_CONFLICTS_WITH_BASHLY_SELECTOR",
      severity = "error",
      message = "argc annotations or refs in a Bashly-owned file conflict with public argv authority",
      selector = source_handler,
      path = relpath,
    })
    table.insert(diagnostics_out, {
      source = "bashly-projector",
      code = "ARGC_REPARSES_BASHLY_OWNED_ARGV",
      severity = "error",
      message = "argc annotations or refs in a Bashly-owned file reparse Bashly-owned argv",
      selector = source_handler,
      path = relpath,
    })
  end

  return facts, facts_by_name
end

local function scan_refs(lines, relpath, facts_by_name, owned_file, selectors_out, diagnostics_out)
  local refs = {}
  local selector_map = selectors_out
  local owned = owned_file[relpath] == true
  local source_handler = selectors.handler(handler_name(relpath))
  local saw_ref = false

  for line_index, line in ipairs(lines) do
    local search_pos = 1
    while true do
      local plain_start, plain_end, plain_name = line:find("%$argc_([%w_]+)", search_pos)
      local brace_start, brace_end, brace_name = line:find("%$%{argc_([%w_]+)%}", search_pos)
      local start_idx, end_idx, name

      if plain_start and (not brace_start or plain_start <= brace_start) then
        start_idx, end_idx, name = plain_start, plain_end, plain_name
      elseif brace_start then
        start_idx, end_idx, name = brace_start, brace_end, brace_name
      end

      if not start_idx then
        break
      end

      saw_ref = true
      local selector_id = ref_selector(relpath, name, line_index - 1, start_idx)
      local resolved_fact = facts_by_name[name]
      local resolved = resolved_fact ~= nil
      local ref = {
        name = name,
        source_file = relpath,
        range = range_from_span(line_index - 1, start_idx, end_idx),
        selector = selector_id,
        resolved = resolved,
      }
      if resolved then
        ref.target_selector = resolved_fact.selector
      end
      table.insert(refs, ref)
      selector_map[selector_id] = {
        id = selector_id,
        kind = "argc_ref",
        path = relpath,
        range = ref.range,
        parent = ref.target_selector,
        children = {},
      }
      if resolved_fact and selector_map[resolved_fact.selector] then
        local entry = selector_map[resolved_fact.selector]
        entry.children = entry.children or {}
        table.insert(entry.children, selector_id)
      end

      if not resolved then
        table.insert(diagnostics_out, {
          source = "bashly-projector",
          code = "ARGC_VAR_REF_UNKNOWN",
          severity = "error",
          message = string.format("%s is used by argc but is not declared in the local argc annotations", name),
          selector = selector_id,
          path = relpath,
          range = ref.range,
        })
      end

      search_pos = end_idx + 1
    end
  end

  if owned and saw_ref then
    table.insert(diagnostics_out, {
      source = "bashly-projector",
      code = "ARGC_CONFLICTS_WITH_BASHLY_SELECTOR",
      severity = "error",
      message = "argc refs in a Bashly-owned file conflict with public argv authority",
      selector = source_handler,
      path = relpath,
    })
    table.insert(diagnostics_out, {
      source = "bashly-projector",
      code = "ARGC_REPARSES_BASHLY_OWNED_ARGV",
      severity = "error",
      message = "argc refs in a Bashly-owned file reparse Bashly-owned argv",
      selector = source_handler,
      path = relpath,
    })
  end

  return refs
end

local function unused_annotation_diagnostics(relpath, facts, refs, diagnostics_out)
  local used = {}
  for _, ref in ipairs(refs) do
    if ref.target_selector then
      used[ref.target_selector] = true
    end
  end

  for _, fact in ipairs(facts) do
    if ref_annotation_kinds[fact.kind] and not used[fact.selector] then
      table.insert(diagnostics_out, {
        source = "bashly-projector",
        code = "ARGC_ANNOTATION_UNUSED",
        severity = "warning",
        message = string.format("argc annotation %s is not used by any argc ref", fact.name),
        selector = fact.selector,
        path = relpath,
        range = fact.range,
      })
    end
  end
end

function M.project_argc(projection)
  local files = (projection and projection.source and projection.source.files) or {}
  local owned_file = command_lookup(projection)
  local selectors_out = {}
  local diagnostics_out = {}
  local facts_out = {}
  local refs_out = {}

  for relpath, file_projection in pairs(files) do
    local bufnr = file_projection and file_projection.nvim and file_projection.nvim.bufnr
    if bufnr and bufnr > 0 then
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local facts, facts_by_name = scan_annotations(lines, relpath, owned_file, selectors_out, diagnostics_out)
      local refs = scan_refs(lines, relpath, facts_by_name, owned_file, selectors_out, diagnostics_out)
      unused_annotation_diagnostics(relpath, facts, refs, diagnostics_out)

      for _, fact in ipairs(facts) do
        table.insert(facts_out, fact)
      end
      for _, ref in ipairs(refs) do
        table.insert(refs_out, ref)
      end
    end
  end

  return {
    facts = facts_out,
    refs = refs_out,
    selectors = selectors_out,
    diagnostics = diagnostics_out,
  }
end

return M

local ast = require("bashly_bridge.ast")
local diagnostics = require("bashly_bridge.diagnostics")
local hash = require("bashly_bridge.hash")
local selectors = require("bashly_bridge.selectors")

local M = {}

local function repo_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  local module_dir = vim.fn.fnamemodify(source, ":p:h")
  return vim.fn.fnamemodify(module_dir, ":h:h")
end

local function decode_json(text)
  return vim.json.decode(text)
end

local function inspect_project(workspace)
  local inspect = repo_root() .. "/bin/bashly-inspect"
  local output = vim.fn.system({ inspect, workspace })
  if vim.v.shell_error ~= 0 then
    error(output)
  end
  return decode_json(output)
end

local function glob_source_files(source_dir)
  local files = vim.fn.globpath(source_dir, "**/*.sh", false, true)
  table.sort(files)
  return files
end

local function handler_name_from_relpath(relpath)
  local stem = relpath:gsub("^.*/", ""):gsub("_command%.sh$", "")
  stem = stem:gsub("%.sh$", "")
  stem = stem:gsub("_", ".")
  if stem == "root" or stem == "" then
    return "root"
  end
  return stem
end

local function file_stem_from_relpath(relpath)
  local stem = relpath:gsub("^.*/", ""):gsub("%.sh$", "")
  stem = stem:gsub("_command$", "")
  return stem
end

local function whole_file_range(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 0 then
    return {
      start_line = 0,
      start_column = 0,
      end_line = 0,
      end_column = 0,
    }
  end

  local last_line = vim.api.nvim_buf_get_lines(bufnr, line_count - 1, line_count, false)[1] or ""
  return {
    start_line = 0,
    start_column = 0,
    end_line = line_count - 1,
    end_column = #last_line,
  }
end

local function load_buffer(path)
  local bufnr = vim.fn.bufnr(path, false)
  if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then
    return bufnr
  end

  vim.cmd("silent keepalt keepjumps noswapfile edit " .. vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end

local function source_selector_record(id, kind, path, range, file_sha256, node_sha256, bufnr)
  local record = {
    id = id,
    kind = kind,
    path = path,
    range = range,
    children = {},
    hashes = {
      file_sha256 = file_sha256,
    },
    nvim = {
      bufnr = bufnr,
      changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
    },
  }

  if node_sha256 then
    record.hashes.node_sha256 = node_sha256
  end

  return record
end

local function project_file(relpath, abs_path, selectors_map, diagnostics_out)
  local bufnr = load_buffer(abs_path)
  local file_sha256 = hash.sha256_file(abs_path)
  local buffer_sha256 = hash.sha256_buffer(bufnr)
  local range = whole_file_range(bufnr)
  local nvim_state = {
    bufnr = bufnr,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
  }

  local file_selector_id = selectors.file(relpath)
  local handler_name = handler_name_from_relpath(relpath)
  local command_selector_id = selectors.whole_command(file_stem_from_relpath(relpath))
  local handler_selector_id = selectors.handler(handler_name)

  local file_record = {
    path = relpath,
    file_sha256 = file_sha256,
    nvim = nvim_state,
    entities = {},
  }

  local file_entity = {
    id = file_selector_id,
    kind = "source_file",
    path = relpath,
    range = range,
    hashes = {
      file_sha256 = file_sha256,
      node_sha256 = buffer_sha256,
    },
    nvim = nvim_state,
  }
  table.insert(file_record.entities, file_entity)
  selectors_map[file_selector_id] = source_selector_record(
    file_selector_id,
    "source_file",
    relpath,
    range,
    file_sha256,
    buffer_sha256,
    bufnr
  )

  local command_entity = {
    id = command_selector_id,
    kind = "source_command",
    path = relpath,
    range = range,
    hashes = {
      file_sha256 = file_sha256,
      node_sha256 = buffer_sha256,
    },
    nvim = nvim_state,
  }
  table.insert(file_record.entities, command_entity)
  selectors_map[command_selector_id] = source_selector_record(
    command_selector_id,
    "source_command",
    relpath,
    range,
    file_sha256,
    buffer_sha256,
    bufnr
  )

  local handler_entity = {
    id = handler_selector_id,
    kind = "source_handler",
    path = relpath,
    range = range,
    hashes = {
      file_sha256 = file_sha256,
      node_sha256 = buffer_sha256,
    },
    nvim = nvim_state,
  }
  table.insert(file_record.entities, handler_entity)
  selectors_map[handler_selector_id] = source_selector_record(
    handler_selector_id,
    "source_handler",
    relpath,
    range,
    file_sha256,
    buffer_sha256,
    bufnr
  )

  local ast_entities, ast_error = ast.project_buffer(bufnr, file_stem_from_relpath(relpath))
  if ast_error == "TREESITTER_BASH_UNAVAILABLE" then
    table.insert(
      diagnostics_out,
      diagnostics.treesitter_unavailable(relpath, file_selector_id)
    )
  elseif ast_entities then
    for _, entity in ipairs(ast_entities) do
      entity.path = relpath
      entity.nvim = nvim_state
      entity.node = nil
      table.insert(file_record.entities, entity)
      selectors_map[entity.id] = {
        id = entity.id,
        kind = entity.kind,
        path = relpath,
        range = entity.range,
        children = {},
        hashes = entity.hashes,
        nvim = nvim_state,
      }
    end
  end

  for _, diagnostic in ipairs(diagnostics.normalize_buffer(bufnr)) do
    table.insert(diagnostics_out, diagnostic)
  end

  return file_record
end

function M.source_projection(workspace)
  local discovered = inspect_project(workspace or ".")
  local workspace_root = discovered.workspace
  local source_dir = workspace_root .. "/" .. discovered.source_dir
  local files = glob_source_files(source_dir)
  local selectors_map = {}
  local diagnostics_out = {}
  local projected_files = {}

  for _, abs_path in ipairs(files) do
    local relpath = abs_path
    if relpath:sub(1, #workspace_root + 1) == workspace_root .. "/" then
      relpath = relpath:sub(#workspace_root + 2)
    end
    projected_files[relpath] = project_file(relpath, abs_path, selectors_map, diagnostics_out)
  end

  return {
    schema_version = 1,
    workspace = workspace_root,
    source = {
      dir = discovered.source_dir,
      files = projected_files,
    },
    selectors = selectors_map,
    diagnostics = diagnostics_out,
  }
end

return M

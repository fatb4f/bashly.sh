local join = require("bashly_bridge.join")
local gate = require("bashly_bridge.gate")
local argc = require("bashly_bridge.argc")
local refs = require("bashly_bridge.refs")
local publisher = require("bashly_bridge.publish_diagnostics")
local source = require("bashly_bridge.source")

local M = {}

function M.source_projection(workspace)
  return source.source_projection(workspace)
end

function M.print_source_projection(workspace)
  io.write(vim.json.encode(M.source_projection(workspace)), "\n")
end

local function repo_root()
  local source_file = debug.getinfo(1, "S").source:sub(2)
  local module_dir = vim.fn.fnamemodify(source_file, ":p:h")
  return vim.fn.fnamemodify(module_dir, ":h:h")
end

local function decode_json(text)
  return vim.json.decode(text)
end

local function load_graph_projection(workspace)
  local command = {
    repo_root() .. "/bin/bashly-project",
    "--graph-only",
    workspace,
  }
  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    error(output)
  end
  return decode_json(output)
end

function M.project_bashly_cli(workspace)
  local graph_projection = load_graph_projection(workspace or ".")
  local source_projection = source.source_projection(workspace or ".")
  local joined = join.join(graph_projection, source_projection)
  local refs_out = {}
  local diagnostics_out = joined.diagnostics or {}

  for _, command in ipairs(joined.bashly.commands or {}) do
    if command.handler_selector and command.source_file then
      local file_projection = joined.source.files[command.source_file]
      if file_projection and file_projection.nvim and file_projection.nvim.bufnr then
        local command_refs = refs.extract_bashly_args_refs(file_projection.nvim.bufnr, command)
        for _, ref in ipairs(command_refs) do
          table.insert(refs_out, ref)
        end
        for _, diagnostic in ipairs(refs.diagnostics_for_command(command, command_refs)) do
          table.insert(diagnostics_out, diagnostic)
        end
      end
    end
  end

  local argc_out = argc.project_argc(joined)
  joined.argc = {
    facts = argc_out.facts or {},
    refs = argc_out.refs or {},
  }

  for selector_id, selector in pairs(argc_out.selectors or {}) do
    if not joined.selectors[selector_id] then
      joined.selectors[selector_id] = selector
    end
  end

  for _, diagnostic in ipairs(argc_out.diagnostics or {}) do
    table.insert(diagnostics_out, diagnostic)
  end

  joined.refs = refs_out
  joined.diagnostics = diagnostics_out
  joined.gate = gate.diagnostic_gate(diagnostics_out)
  return joined
end

function M.print_bashly_cli(workspace)
  io.write(vim.json.encode(M.project_bashly_cli(workspace)), "\n")
end

function M.project_bashly_cli_and_publish(workspace)
  local projection = M.project_bashly_cli(workspace)
  publisher.publish(projection)
  return projection
end

function M.print_bashly_cli_and_publish(workspace)
  io.write(vim.json.encode(M.project_bashly_cli_and_publish(workspace)), "\n")
end

return M

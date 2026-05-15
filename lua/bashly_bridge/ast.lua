local hash = require("bashly_bridge.hash")

local M = {}

local function node_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return {
    start_line = start_row,
    start_column = start_col,
    end_line = end_row,
    end_column = end_col,
  }
end

local function node_text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr) or ""
end

local function function_name_from_text(text)
  return text:match("^%s*function%s+([%w_][%w_%-]*)%s*%(")
    or text:match("^%s*([%w_][%w_%-]*)%s*%(")
end

function M.project_buffer(bufnr, file_stem)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "bash")
  if not ok or not parser then
    return nil, "TREESITTER_BASH_UNAVAILABLE"
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}, nil
  end

  local query = vim.treesitter.query.parse(
    "bash",
    [[
      (function_definition) @function_definition
      (case_statement) @case_statement
      (variable_assignment) @variable_assignment
      (command) @command
    ]]
  )

  local root = tree:root()
  local captures = {}

  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local capture = query.captures[id]
    local range = node_range(node)
    local text = node_text(node, bufnr)
    local node_hash = hash.sha256_text(text)
    local selector_id = nil
    local kind = nil

    if capture == "function_definition" then
      local name = function_name_from_text(text)
      if name then
        selector_id = "source.function." .. name
      else
        selector_id = string.format("source.function.%s.%d_%d", file_stem, range.start_line, range.start_column)
      end
      kind = "source_function"
    elseif capture == "case_statement" then
      selector_id = string.format("source.case.%s.%d_%d", file_stem, range.start_line, range.start_column)
      kind = "source_case"
    elseif capture == "variable_assignment" then
      selector_id = string.format("source.assignment_block.%s.%d_%d", file_stem, range.start_line, range.start_column)
      kind = "source_assignment_block"
    elseif capture == "command" then
      selector_id = string.format("source.command.%s.%d_%d", file_stem, range.start_line, range.start_column)
      kind = "source_command"
    end

    if selector_id then
      table.insert(captures, {
        id = selector_id,
        kind = kind,
        path = nil,
        range = range,
        hashes = {
          node_sha256 = node_hash,
        },
        node = node,
      })
    end
  end

  return captures, nil
end

return M

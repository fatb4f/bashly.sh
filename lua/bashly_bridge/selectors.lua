local M = {}

local function normalize_path(path)
  return (path or ""):gsub("\\", "/")
end

local function stable_id(prefix, stem, node)
  local row, col = node:range()
  return string.format("%s.%s.%d_%d", prefix, stem, row, col)
end

function M.file(path)
  return "source.file." .. normalize_path(path)
end

function M.command(stem, node)
  return stable_id("source.command", stem, node)
end

function M.whole_command(stem)
  return "source.command." .. stem .. ".whole_file"
end

function M.handler(name)
  return "source.handler." .. name
end

function M.function_name(name)
  return "source.function." .. name
end

function M.case(stem, node)
  return stable_id("source.case", stem, node)
end

function M.assignment_block(stem, node)
  return stable_id("source.assignment_block", stem, node)
end

return M

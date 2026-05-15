local M = {}

local function normalize_path(path)
  return (path or ""):gsub("\\", "/")
end

local function stable_id(prefix, stem, node)
  local row, col = node:range()
  return string.format("%s.%s.%d_%d", prefix, stem, row, col)
end

local function selector_map(projection)
  return (projection and projection.selectors) or {}
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

function M.argc_fact(kind, stem, name, line, column)
  return string.format("argc.fact.%s.%s.%s.%d_%d", kind, stem, name, line, column)
end

function M.argc_ref(stem, name, line, column)
  return string.format("argc.ref.%s.%s.%d_%d", stem, name, line, column)
end

function M.argc_annotation(stem, kind, name, line, column)
  return string.format("argc.annotation.%s.%s.%s.%d_%d", kind, stem, name, line, column)
end

function M.get_selector(projection, selector_id)
  return selector_map(projection)[selector_id]
end

function M.selector_has_range(selector)
  return type(selector) == "table" and selector.range ~= nil
end

function M.selector_buffer(projection, selector)
  if type(selector) ~= "table" then
    return nil, nil
  end

  local files = (projection and projection.source and projection.source.files) or {}
  local path = selector.path
  if not path then
    return nil, nil
  end

  local file_projection = files[path]
  if file_projection and file_projection.nvim and file_projection.nvim.bufnr then
    return file_projection.nvim.bufnr, file_projection
  end

  local bufnr = vim.fn.bufnr(path, false)
  if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then
    return bufnr, file_projection
  end

  return nil, file_projection
end

return M

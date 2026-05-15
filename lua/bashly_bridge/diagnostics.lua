local M = {}

local severity_names = {
  [vim.diagnostic.severity.ERROR] = "error",
  [vim.diagnostic.severity.WARN] = "warning",
  [vim.diagnostic.severity.INFO] = "info",
  [vim.diagnostic.severity.HINT] = "hint",
}

local function range_from_diag(diag)
  if diag.lnum == nil then
    return nil
  end

  return {
    start_line = diag.lnum,
    start_column = diag.col or 0,
    end_line = diag.end_lnum or diag.lnum,
    end_column = diag.end_col or (diag.col or 0),
  }
end

local function code_from_diag(diag)
  if diag.code == nil then
    return "UNKNOWN"
  end

  return tostring(diag.code)
end

function M.normalize(diag, path)
  local result = {
    source = diag.source or "vim.diagnostic",
    code = code_from_diag(diag),
    severity = severity_names[diag.severity] or "info",
    message = diag.message or "",
    path = path,
  }

  local range = range_from_diag(diag)
  if range then
    result.range = range
  end

  local selector = nil
  if type(diag.user_data) == "table" then
    selector = diag.user_data.selector
  end
  selector = selector or diag.selector
  if selector then
    result.selector = selector
  end

  return result
end

function M.normalize_buffer(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local result = {}
  for _, diag in ipairs(vim.diagnostic.get(bufnr)) do
    table.insert(result, M.normalize(diag, path))
  end
  return result
end

function M.treesitter_unavailable(path, selector)
  return {
    source = "bashly_source",
    code = "TREESITTER_BASH_UNAVAILABLE",
    severity = "warning",
    message = "Tree-sitter Bash parser is unavailable",
    path = path,
    selector = selector,
  }
end

return M

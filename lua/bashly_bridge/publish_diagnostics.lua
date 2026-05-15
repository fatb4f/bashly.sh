local M = {}

local namespace = vim.api.nvim_create_namespace("bashly-projector")

local severity_map = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  info = vim.diagnostic.severity.INFO,
  hint = vim.diagnostic.severity.HINT,
}

local function resolve_path(workspace, path)
  if path == nil or path == "" then
    return nil
  end
  if path:sub(1, 1) == "/" then
    return path
  end
  return workspace .. "/" .. path
end

local function projection_bufnr_map(projection)
  local map = {}
  local workspace = projection.workspace or vim.fn.getcwd()
  for relpath, file in pairs((projection.source and projection.source.files) or {}) do
    local absolute = resolve_path(workspace, file.path or relpath)
    if file.nvim and file.nvim.bufnr then
      map[absolute] = file.nvim.bufnr
    end
    map[relpath] = file.nvim and file.nvim.bufnr or nil
  end
  return map
end

local function range_to_lsp(range)
  if not range then
    return nil
  end

  return {
    lnum = range.start_line or 0,
    col = range.start_column or 0,
    end_lnum = range.end_line or range.start_line or 0,
    end_col = range.end_column or range.start_column or 0,
  }
end

local function normalize_message(diagnostic)
  local message = diagnostic.message or ""
  local selector = diagnostic.selector
  if selector and not message:find("%[selector=", 1, true) then
    message = string.format("[selector=%s] %s", selector, message)
  end
  return message
end

local function to_vim_diagnostic(diagnostic)
  local result = {
    severity = severity_map[diagnostic.severity] or vim.diagnostic.severity.INFO,
    source = diagnostic.source or "bashly-projector",
    code = diagnostic.code,
    message = normalize_message(diagnostic),
    user_data = {
      selector = diagnostic.selector,
      target_selector = diagnostic.target_selector,
      source_selector = diagnostic.source_selector,
      ref = diagnostic.ref,
    },
  }

  local range = range_to_lsp(diagnostic.range)
  result.lnum = 0
  result.col = 0
  result.end_lnum = 0
  result.end_col = 0
  if range then
    result.lnum = range.lnum
    result.col = range.col
    result.end_lnum = range.end_lnum
    result.end_col = range.end_col
  end

  return result
end

function M.namespace()
  return namespace
end

function M.clear()
  vim.diagnostic.reset(namespace)
end

function M.publish(projection)
  M.clear()

  local workspace = projection.workspace or vim.fn.getcwd()
  local bufnrs = projection_bufnr_map(projection)
  local grouped = {}

  for _, diagnostic in ipairs(projection.diagnostics or {}) do
    local path = resolve_path(workspace, diagnostic.path)
    if path then
      grouped[path] = grouped[path] or {}
      table.insert(grouped[path], to_vim_diagnostic(diagnostic))
    end
  end

  for path, diagnostics in pairs(grouped) do
    local bufnr = bufnrs[path]
    if not bufnr then
      bufnr = vim.fn.bufadd(path)
      vim.fn.bufload(bufnr)
    end
    vim.diagnostic.set(namespace, bufnr, diagnostics, {
      severity_sort = true,
    })
  end
end

return M

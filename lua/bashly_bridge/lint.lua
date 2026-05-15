local M = {}

local shellcheck_namespace = vim.api.nvim_create_namespace("bashly-apply-lint")

local function shellcheck_severity(level)
  if level == "error" then
    return "error"
  end
  if level == "info" then
    return "info"
  end
  return "warning"
end

local function buffer_lines(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function write_temp_file(lines)
  local path = vim.fn.tempname()
  vim.fn.writefile(lines, path)
  return path
end

local function parse_shellcheck_json(output, path)
  local decoded = vim.json.decode(output or "[]")
  local diagnostics = {}

  for _, item in ipairs(decoded or {}) do
    local line = item.line or 1
    local column = item.column or 1
    table.insert(diagnostics, {
      source = "shellcheck",
      code = item.code or "SC0000",
      severity = shellcheck_severity(item.level),
      message = item.message or "",
      path = path,
      lnum = math.max(line - 1, 0),
      col = math.max(column - 1, 0),
      end_lnum = math.max(line - 1, 0),
      end_col = math.max(column - 1, 0),
      range = {
        start_line = math.max(line - 1, 0),
        start_column = math.max(column - 1, 0),
        end_line = math.max(line - 1, 0),
        end_column = math.max(column - 1, 0),
      },
    })
  end

  return diagnostics
end

function M.shellcheck_buffer(bufnr, path)
  if vim.fn.executable("shellcheck") ~= 1 then
    return nil, "lint_failed: shellcheck unavailable"
  end

  local tmp = write_temp_file(buffer_lines(bufnr))
  local output = vim.fn.system({ "shellcheck", "-f", "json", tmp })
  local code = vim.v.shell_error
  os.remove(tmp)

  if code > 1 then
    return nil, string.format("lint_failed: shellcheck exited %d", code)
  end

  local ok, diagnostics = pcall(parse_shellcheck_json, output, path)
  if not ok then
    return nil, "lint_failed: unable to parse shellcheck output"
  end

  vim.diagnostic.set(shellcheck_namespace, bufnr, diagnostics, {
    severity_sort = true,
  })

  return {
    namespace = shellcheck_namespace,
    diagnostics = diagnostics,
    exit_code = code,
  }, nil
end

function M.namespace()
  return shellcheck_namespace
end

return M

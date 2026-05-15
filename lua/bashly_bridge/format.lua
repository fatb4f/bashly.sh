local M = {}

local function buffer_text(bufnr)
  return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
end

local function set_buffer_text(bufnr, text)
  local lines = vim.split(text or "", "\n", { plain = true, trimempty = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

local function run_tool(cmd, input)
  local output = vim.fn.system(cmd, input or "")
  local code = vim.v.shell_error
  return output, code
end

function M.normalize_shellharden(bufnr, path)
  if vim.fn.executable("shellharden") ~= 1 then
    return nil, "normalizer_failed: shellharden unavailable"
  end

  local input = buffer_text(bufnr)
  local output, code = run_tool({ "shellharden", "--transform", "" }, input)
  if code > 1 or output == nil then
    return nil, string.format("normalizer_failed: shellharden exited %d", code)
  end

  set_buffer_text(bufnr, output)
  return {
    changed = output ~= input,
    tool = "shellharden",
    path = path,
  }, nil
end

function M.format_shfmt(bufnr, path)
  if vim.fn.executable("shfmt") ~= 1 then
    return nil, "formatter_failed: shfmt unavailable"
  end

  local input = buffer_text(bufnr)
  local output, code = run_tool({ "shfmt", "-filename", path, "-i", "2", "-ci" }, input)
  if code > 1 or output == nil then
    return nil, string.format("formatter_failed: shfmt exited %d", code)
  end

  set_buffer_text(bufnr, output)
  return {
    changed = output ~= input,
    tool = "shfmt",
    path = path,
  }, nil
end

return M

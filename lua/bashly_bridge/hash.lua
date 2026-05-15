local M = {}

function M.sha256_text(text)
  return "sha256:" .. vim.fn.sha256(text or "")
end

function M.sha256_file(path)
  local handle, err = io.open(path, "rb")
  if not handle then
    error(err)
  end

  local data = handle:read("*a")
  handle:close()
  return M.sha256_text(data or "")
end

function M.sha256_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return M.sha256_text(table.concat(lines, "\n"))
end

return M

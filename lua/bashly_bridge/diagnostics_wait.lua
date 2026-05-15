local M = {}

function M.wait_for_stable(bufnr, namespace, timeout_ms)
  local timeout = timeout_ms or 1000
  local last_count = nil
  local stable_count = 0

  local ok = vim.wait(timeout, function()
    local count = #vim.diagnostic.get(bufnr, { namespace = namespace })
    if count == last_count then
      stable_count = stable_count + 1
    else
      stable_count = 0
    end
    last_count = count
    return stable_count >= 1
  end, 20)

  return ok, {
    namespace = namespace,
    timeout_ms = timeout,
    stable = ok and stable_count >= 1,
    count = #vim.diagnostic.get(bufnr, { namespace = namespace }),
  }
end

return M

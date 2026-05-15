local M = {}

local blocking_codes = {
  BASHLY_SOURCE_FILE_MISSING = true,
  BASHLY_HANDLER_MISSING = true,
  SELECTOR_DUPLICATE = true,
  BASHLY_ARGS_REF_UNKNOWN = true,
}

function M.diagnostic_gate(diagnostics)
  local gate = {
    green = true,
    blocking_count = 0,
    warning_count = 0,
    info_count = 0,
    blocking_codes = {},
  }

  local blocking_seen = {}

  for _, diagnostic in ipairs(diagnostics or {}) do
    local severity = diagnostic.severity
    if severity == "warning" then
      gate.warning_count = gate.warning_count + 1
    elseif severity == "info" then
      gate.info_count = gate.info_count + 1
    end

    local is_blocking = severity == "error" or blocking_codes[diagnostic.code]
    if is_blocking then
      gate.blocking_count = gate.blocking_count + 1
      gate.green = false
      local code = diagnostic.code or "ERROR"
      if not blocking_seen[code] then
        blocking_seen[code] = true
        table.insert(gate.blocking_codes, code)
      end
    end
  end

  return gate
end

return M

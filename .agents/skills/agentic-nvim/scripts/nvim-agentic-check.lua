local ok, agentic = pcall(require, "agentic")
if not ok then
  error("agentic.nvim not loadable: " .. tostring(agentic))
end

local required = {
  "open",
  "close",
  "toggle",
  "rotate_layout",
  "add_selection",
  "add_file",
  "add_files_to_context",
  "add_selection_or_file_to_context",
  "add_current_line_diagnostics",
  "add_buffer_diagnostics",
  "new_session",
  "new_session_with_provider",
  "restore_session",
  "restore_session_by_id",
  "switch_provider",
  "stop_generation",
}

local missing = {}
for _, name in ipairs(required) do
  if type(agentic[name]) ~= "function" then
    table.insert(missing, name)
  end
end

if #missing > 0 then
  error("missing agentic API: " .. table.concat(missing, ", "))
end

print("agentic.nvim API check: ok")

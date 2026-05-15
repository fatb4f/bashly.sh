local project = require("bashly_bridge.project")
local publisher = require("bashly_bridge.publish_diagnostics")

local function notify_gate(projection)
  local gate = projection.gate or {}
  vim.notify(
    string.format(
      "bashly_project: green=%s blocking=%d warnings=%d info=%d",
      tostring(gate.green),
      gate.blocking_count or 0,
      gate.warning_count or 0,
      gate.info_count or 0
    )
  )
end

vim.api.nvim_create_user_command("BashlyProject", function(opts)
  local workspace = opts.args ~= "" and opts.args or vim.fn.getcwd()
  local projection = project.project_bashly_cli(workspace)
  publisher.publish(projection)
  notify_gate(projection)
end, {
  nargs = "?",
})

vim.api.nvim_create_user_command("BashlyDiagnosticsPublish", function(opts)
  local workspace = opts.args ~= "" and opts.args or vim.fn.getcwd()
  local projection = project.project_bashly_cli(workspace)
  publisher.publish(projection)
end, {
  nargs = "?",
})

vim.api.nvim_create_user_command("BashlyDiagnosticsClear", function()
  publisher.clear()
end, {})

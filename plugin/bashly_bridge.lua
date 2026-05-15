local project = require("bashly_bridge.project")
local apply = require("bashly_bridge.apply")
local generate_verify = require("bashly_bridge.generate_verify")
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

vim.api.nvim_create_user_command("BashlyApplyChunkDebug", function(opts)
  local args = opts.fargs or {}
  local selector = args[1]
  local action = args[2] or "append"
  local content = ""
  if #args > 2 then
    content = table.concat(args, " ", 3)
  end

  local result = apply.apply_bashly_chunk({
    workspace = vim.fn.getcwd(),
    target = {
      selector = selector,
    },
    action = {
      kind = action,
      content = content,
    },
  })

  print(vim.json.encode(result))
end, {
  nargs = "+",
  complete = function()
    return { "source.handler.root", "source.handler.hello", "bashly.command.root", "bashly.command.hello" }
  end,
})

vim.api.nvim_create_user_command("BashlyGenerateVerifyDebug", function(opts)
  local workspace = opts.args ~= "" and opts.args or vim.fn.getcwd()
  print(vim.json.encode(generate_verify.generate_verify(workspace, {})))
end, {
  nargs = "?",
})

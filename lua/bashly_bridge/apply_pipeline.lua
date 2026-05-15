local format = require("bashly_bridge.format")
local lint = require("bashly_bridge.lint")
local wait = require("bashly_bridge.diagnostics_wait")

local M = {}

local apply_namespace = vim.api.nvim_create_namespace("bashly-apply")

local function source_only_target(path)
  if type(path) ~= "string" then
    return false
  end
  return path:match("^src/") ~= nil and path:match("%.sh$") ~= nil
end

local function merge_lists(a, b)
  local merged = {}
  for _, item in ipairs(a or {}) do
    table.insert(merged, item)
  end
  for _, item in ipairs(b or {}) do
    table.insert(merged, item)
  end
  return merged
end

local function bump_gate(base_gate, diagnostics)
  local gate = vim.deepcopy(base_gate or {
    green = true,
    blocking_count = 0,
    warning_count = 0,
    info_count = 0,
    blocking_codes = {},
  })

  for _, diagnostic in ipairs(diagnostics or {}) do
    if diagnostic.severity == "warning" then
      gate.warning_count = gate.warning_count + 1
    elseif diagnostic.severity == "info" then
      gate.info_count = gate.info_count + 1
    elseif diagnostic.severity == "error" then
      gate.blocking_count = gate.blocking_count + 1
      gate.green = false
      table.insert(gate.blocking_codes, diagnostic.code or "ERROR")
    end
  end

  return gate
end

local function validate_pipeline_request(pipeline)
  if pipeline == nil then
    return true
  end

  local allowed = {
    finalize = true,
    normalize = true,
    format = true,
    write = true,
    lint = true,
    diagnostics_wait = true,
  }

  for key, value in pairs(pipeline) do
    if not allowed[key] or type(value) ~= "boolean" then
      return false
    end
  end

  return true
end

function M.finalize(resolution, projection, action_kind, opts)
  if not validate_pipeline_request(opts.pipeline) then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = resolution.path,
      action = action_kind,
      phases = opts.phases,
      diagnostics = {},
      gate = {
        green = false,
        blocking_count = 1,
        warning_count = 0,
        info_count = 0,
        blocking_codes = { "unsupported_phase" },
      },
      error = {
        code = "unsupported_phase",
        message = "The requested pipeline contains unsupported phase settings.",
        selector = opts.selector_id,
        path = resolution.path,
      },
    }
  end

  local path = resolution.path
  if not source_only_target(path) then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = path,
      action = action_kind,
      phases = opts.phases,
      diagnostics = {},
      gate = {
        green = false,
        blocking_count = 1,
        warning_count = 0,
        info_count = 0,
        blocking_codes = { "unsafe_write_target" },
      },
      error = {
        code = "unsafe_write_target",
        message = "Only src/*.sh files may be finalized by this pipeline.",
        selector = opts.selector_id,
        path = path,
      },
    }
  end

  local phases = vim.deepcopy(opts.phases or {})
  local current_gate = vim.deepcopy(projection.gate or {})
  local diagnostics = merge_lists(projection.diagnostics or {}, {})

  local normalize_result, normalize_err = format.normalize_shellharden(resolution.bufnr, path)
  if normalize_err then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = path,
      action = action_kind,
      phases = phases,
      diagnostics = diagnostics,
      gate = current_gate,
      error = {
        code = "normalizer_failed",
        message = normalize_err,
        selector = opts.selector_id,
        path = path,
      },
    }
  end
  phases.normalize = true
  if normalize_result and normalize_result.changed then
    vim.api.nvim_buf_set_option(resolution.bufnr, "modified", true)
  end

  local format_result, format_err = format.format_shfmt(resolution.bufnr, path)
  if format_err then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = path,
      action = action_kind,
      phases = phases,
      diagnostics = diagnostics,
      gate = current_gate,
      error = {
        code = "formatter_failed",
        message = format_err,
        selector = opts.selector_id,
        path = path,
      },
    }
  end
  phases.formatted = true
  if format_result and format_result.changed then
    vim.api.nvim_buf_set_option(resolution.bufnr, "modified", true)
  end

  local write_ok, write_err = pcall(function()
    vim.api.nvim_set_current_buf(resolution.bufnr)
    vim.cmd("silent write")
  end)
  if not write_ok then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = path,
      action = action_kind,
      phases = phases,
      diagnostics = diagnostics,
      gate = current_gate,
      error = {
        code = "write_failed",
        message = tostring(write_err),
        selector = opts.selector_id,
        path = path,
      },
    }
  end
  phases.written = true

  local lint_result, lint_err = lint.shellcheck_buffer(resolution.bufnr, path)
  if lint_err then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = path,
      action = action_kind,
      phases = phases,
      diagnostics = diagnostics,
      gate = current_gate,
      error = {
        code = "lint_failed",
        message = lint_err,
        selector = opts.selector_id,
        path = path,
      },
    }
  end
  phases.linted = true
  local wait_ok, wait_result = wait.wait_for_stable(resolution.bufnr, lint.namespace(), 1000)
  phases.diagnostics_settled = wait_ok
  if not wait_ok then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = path,
      action = action_kind,
      phases = phases,
      diagnostics = diagnostics,
      gate = current_gate,
      error = {
        code = "diagnostics_timeout",
        message = "Diagnostics did not settle before timeout.",
        selector = opts.selector_id,
        path = path,
      },
    }
  end

  diagnostics = merge_lists(diagnostics, lint_result.diagnostics or {})
  current_gate = bump_gate(current_gate, lint_result.diagnostics or {})

  local post_projection = projection
  local reprojected, reprojection_err = pcall(function()
    post_projection = require("bashly_bridge.project").project_bashly_cli(opts.workspace or ".")
  end)
  if not reprojected then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = path,
      action = action_kind,
      phases = phases,
      diagnostics = diagnostics,
      gate = current_gate,
      error = {
        code = "post_projection_failed",
        message = tostring(reprojection_err),
        selector = opts.selector_id,
        path = path,
      },
    }
  end
  phases.reprojected = true

  if current_gate.blocking_count > 0 then
    return nil, {
      applied = false,
      ok = false,
      selector = opts.selector_id,
      path = path,
      action = action_kind,
      phases = phases,
      diagnostics = diagnostics,
      gate = current_gate,
      error = {
        code = "post_gate_blocked",
        message = "Final gate is blocking after lint and reprojection.",
        selector = opts.selector_id,
        path = path,
      },
    }
  end

  post_projection.diagnostics = diagnostics
  post_projection.gate = current_gate

  return {
    applied = true,
    ok = true,
    selector = opts.selector_id,
    path = path,
    action = action_kind,
    phases = phases,
    projection = post_projection,
    diagnostics = diagnostics,
    gate = current_gate,
    error = nil,
  }, nil
end

return M

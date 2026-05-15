local pipeline = require("bashly_bridge.apply_pipeline")
local project = require("bashly_bridge.project")
local selectors = require("bashly_bridge.selectors")

local M = {}

local supported_actions = {
  append = true,
  replace_body = true,
  replace_node = true,
  insert_before = true,
  insert_after = true,
}

local function default_phases()
  return {
    projected = false,
    resolved = false,
    guarded = false,
    mutated = false,
    normalize = false,
    formatted = false,
    written = false,
    linted = false,
    diagnostics_settled = false,
    reprojected = false,
  }
end

local function make_error(selector, path, action, code, message, phases)
  return {
    applied = false,
    ok = false,
    selector = selector,
    path = path,
    action = action,
    phases = phases or default_phases(),
    projection = nil,
    diagnostics = {},
    gate = {
      green = false,
      blocking_count = 1,
      warning_count = 0,
      info_count = 0,
      blocking_codes = { code },
    },
    error = {
      code = code,
      message = message,
      selector = selector,
      path = path,
    },
  }
end

local function request_target(req)
  local target = req.target or {}
  return target.selector or req.selector
end

local function request_action(req)
  local action = req.action or {}
  if type(action) == "table" then
    return action.kind or req.action_kind or req.action, action.content or req.content or ""
  end

  return action or req.action_kind, req.content or ""
end

local function request_guards(req)
  return req.guard or req.guards or {}
end

local function request_finalize(req)
  if req.finalize ~= nil then
    return req.finalize
  end

  local pipeline_req = req.pipeline or {}
  if type(pipeline_req) == "table" and pipeline_req.finalize ~= nil then
    return pipeline_req.finalize
  end

  return false
end

local function split_lines(content)
  if content == nil or content == "" then
    return {}
  end
  return vim.split(content, "\n", { plain = true, trimempty = true })
end

local function resolve_selector(projection, selector_id)
  local selector = selectors.get_selector(projection, selector_id)
  if not selector then
    return nil, make_error(selector_id, nil, nil, "unknown_selector", "Unknown selector.", default_phases())
  end

  local bufnr, file_projection = selectors.selector_buffer(projection, selector)
  local path = selector.path
  if file_projection and file_projection.path then
    path = file_projection.path
  end

  if not path then
    return nil, make_error(selector_id, nil, nil, "unresolved_source_file", "Selector has no resolvable source file.", default_phases())
  end

  if not bufnr then
    local abs_path = (projection.workspace or vim.fn.getcwd()) .. "/" .. path
    vim.cmd("silent keepalt keepjumps noswapfile edit " .. vim.fn.fnameescape(abs_path))
    bufnr = vim.api.nvim_get_current_buf()
  end

  return {
    selector = selector,
    bufnr = bufnr,
    path = path,
    file_projection = file_projection,
  }, nil
end

local function check_guard(expected, actual, code, selector_id, path, phases)
  if expected ~= nil and expected ~= actual then
    return make_error(
      selector_id,
      path,
      nil,
      code,
      string.format("Guard mismatch for %s.", code),
      phases
    )
  end
  return nil
end

local function verify_guards(resolution, guards, selector_id)
  local phases = default_phases()
  phases.resolved = true

  local selector = resolution.selector
  local bufnr = resolution.bufnr
  local path = resolution.path
  local file_projection = resolution.file_projection or {}

  local file_sha256 = file_projection.file_sha256 or selector.hashes and selector.hashes.file_sha256
  local node_sha256 = selector.hashes and selector.hashes.node_sha256
  local changedtick = selector.nvim and selector.nvim.changedtick

  local mismatch =
    check_guard(guards.file_sha256, file_sha256, "stale_file_hash", selector_id, path, phases)
    or check_guard(guards.node_sha256, node_sha256, "stale_node_hash", selector_id, path, phases)
    or check_guard(guards.changedtick, changedtick, "stale_changedtick", selector_id, path, phases)

  if mismatch then
    return nil, mismatch
  end

  if not selectors.selector_has_range(selector) and guards.action ~= "append" then
    return nil, make_error(
      selector_id,
      path,
      guards.action,
      "selector_has_no_range",
      "Selector does not expose a usable range for this action.",
      phases
    )
  end

  phases.guarded = true

  return {
    selector = selector,
    bufnr = bufnr,
    path = path,
    file_projection = file_projection,
    phases = phases,
  }, nil
end

local function apply_mutation(resolution, action_kind, content)
  local bufnr = resolution.bufnr
  local selector = resolution.selector
  local range = selector.range
  local lines = split_lines(content)
  local prev_modifiable = vim.bo[bufnr].modifiable
  local prev_readonly = vim.bo[bufnr].readonly
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false

  local ok, err = pcall(function()
    if action_kind == "append" then
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      if line_count == 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      else
        vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, lines)
      end
      return
    end

    if not range then
      error("selector has no range")
    end

    if action_kind == "insert_before" then
      vim.api.nvim_buf_set_text(
        bufnr,
        range.start_line,
        range.start_column,
        range.start_line,
        range.start_column,
        lines
      )
    elseif action_kind == "insert_after" then
      vim.api.nvim_buf_set_text(
        bufnr,
        range.end_line,
        range.end_column,
        range.end_line,
        range.end_column,
        lines
      )
    elseif action_kind == "replace_body" or action_kind == "replace_node" then
      vim.api.nvim_buf_set_text(
        bufnr,
        range.start_line,
        range.start_column,
        range.end_line,
        range.end_column,
        lines
      )
    else
      error("unsupported action")
    end
  end)

  vim.bo[bufnr].modifiable = prev_modifiable
  vim.bo[bufnr].readonly = prev_readonly

  if not ok then
    return false, err
  end

  return true, nil
end

local function result_from_projection(selector_id, path, action_kind, projection)
  return {
    applied = true,
    ok = true,
    selector = selector_id,
    path = path,
    action = action_kind,
    phases = {
      projected = true,
      resolved = true,
      guarded = true,
      mutated = true,
      normalize = false,
      formatted = false,
      written = false,
      linted = false,
      diagnostics_settled = false,
      reprojected = true,
    },
    projection = projection,
    diagnostics = projection.diagnostics or {},
    gate = projection.gate or {
      green = true,
      blocking_count = 0,
      warning_count = 0,
      info_count = 0,
      blocking_codes = {},
    },
    error = nil,
  }
end

function M.apply_bashly_chunk(req)
  local selector_id = request_target(req)
  local action_kind, content = request_action(req)
  local guards = request_guards(req)
  local workspace = req.workspace or "."
  local finalize = request_finalize(req)

  if not selector_id then
    return make_error(nil, nil, action_kind, "unknown_selector", "No selector was provided.", default_phases())
  end

  if not supported_actions[action_kind] then
    return make_error(
      selector_id,
      nil,
      action_kind,
      "unsupported_action",
      "The requested action is not supported by this mutation skeleton.",
      default_phases()
    )
  end

  local projection
  local ok, err = pcall(function()
    projection = project.project_bashly_cli(workspace)
  end)
  if not ok then
    return make_error(
      selector_id,
      nil,
      action_kind,
      "post_projection_failed",
      tostring(err),
      default_phases()
    )
  end

  local resolution, resolution_err = resolve_selector(projection, selector_id)
  if resolution_err then
    resolution_err.phases.projected = true
    resolution_err.action = action_kind
    return resolution_err
  end

  local guard_state, guard_err = verify_guards({
    selector = resolution.selector,
    bufnr = resolution.bufnr,
    path = resolution.path,
    file_projection = resolution.file_projection,
  }, vim.tbl_extend("force", guards, { action = action_kind }), selector_id)
  if guard_err then
    guard_err.phases.projected = true
    guard_err.action = action_kind
    return guard_err
  end

  guard_state.phases.projected = true

  local mutated, mutate_err = apply_mutation(guard_state, action_kind, content)
  if not mutated then
    return make_error(
      selector_id,
      guard_state.path,
      action_kind,
      "mutation_failed",
      tostring(mutate_err),
      guard_state.phases
    )
  end
  guard_state.phases.mutated = true

  if not finalize then
    local reprojected, reprojection_err = pcall(function()
      projection = project.project_bashly_cli(workspace)
    end)
    if not reprojected then
      return make_error(
        selector_id,
        guard_state.path,
        action_kind,
        "post_projection_failed",
        tostring(reprojection_err),
        guard_state.phases
      )
    end

    return result_from_projection(selector_id, guard_state.path, action_kind, projection)
  end

  local finalized, finalize_err = pipeline.finalize(guard_state, projection, action_kind, {
    workspace = workspace,
    selector_id = selector_id,
    phases = guard_state.phases,
    pipeline = req.pipeline,
  })
  if finalize_err then
    return finalize_err
  end

  return finalized
end

return M

local M = {}

local function repo_root()
  local source_file = debug.getinfo(1, "S").source:sub(2)
  local module_dir = vim.fn.fnamemodify(source_file, ":p:h")
  return vim.fn.fnamemodify(module_dir, ":h:h")
end

local function decode_json(text)
  return vim.json.decode(text)
end

local function inspect_project(workspace)
  local inspect = repo_root() .. "/bin/bashly-inspect"
  local output = vim.fn.system({ inspect, workspace })
  if vim.v.shell_error ~= 0 then
    error(output)
  end
  return decode_json(output)
end

local function phase(ok, data)
  local result = {
    ok = ok and true or false,
  }
  for key, value in pairs(data or {}) do
    result[key] = value
  end
  return result
end

local function elapsed_ms(started)
  return math.floor((vim.loop.hrtime() - started) / 1e6)
end

local function timeout_result(project_root, phase_name, elapsed, timeout_ms, details)
  return error_result(project_root, "verification_timeout", string.format("verification exceeded timeout budget (%dms > %dms)", elapsed, timeout_ms), phase_name, details)
end

local function error_result(project_root, code, message, phase_name, details)
  return {
    ok = false,
    project = {
      root = project_root,
    },
    phases = details and details.phases or {},
    evidence = details and details.evidence or {},
    errors = {
      {
        code = code,
        message = message,
        phase = phase_name,
        path = details and details.path or nil,
      },
    },
  }
end

local function shell_command(cwd, command)
  local started = vim.loop.hrtime()
  local output = vim.fn.system({ "bash", "-lc", string.format("cd %q && %s 2>&1", cwd, command) })
  local duration_ms = math.floor((vim.loop.hrtime() - started) / 1e6)
  return {
    ok = vim.v.shell_error == 0,
    exit_code = vim.v.shell_error,
    stdout = output or "",
    stderr = "",
    duration_ms = duration_ms,
  }
end

local function generated_executable_path(project_root, generated_outputs)
  local relative = generated_outputs and generated_outputs[1]
  if not relative or relative == "" then
    return nil, "unsupported_project_shape", "No generated executable candidate was discovered."
  end

  local absolute = project_root .. "/" .. relative
  if vim.fn.filereadable(absolute) ~= 1 then
    return nil, "generated_executable_not_found", absolute
  end

  if vim.fn.executable(absolute) ~= 1 then
    return nil, "generated_executable_not_executable", absolute
  end

  return {
    relative = relative,
    absolute = absolute,
  }, nil, nil
end

local function detect_test_runner(project_root)
  local bats_files = vim.fn.globpath(project_root .. "/test", "**/*.bats", false, true)
  for _, path in ipairs(vim.fn.globpath(project_root .. "/tests", "**/*.bats", false, true)) do
    table.insert(bats_files, path)
  end
  if #bats_files > 0 then
    local dirs = {}
    if vim.fn.isdirectory(project_root .. "/test") == 1 then
      table.insert(dirs, "test")
    end
    if vim.fn.isdirectory(project_root .. "/tests") == 1 then
      table.insert(dirs, "tests")
    end
    return {
      kind = "bats",
      dirs = dirs,
      files = bats_files,
    }
  end

  local shellspec_files = vim.fn.globpath(project_root .. "/spec", "**/*_spec.sh", false, true)
  for _, path in ipairs(vim.fn.globpath(project_root .. "/spec", "**/*.shpec", false, true)) do
    table.insert(shellspec_files, path)
  end
  if #shellspec_files > 0 then
    return {
      kind = "shellspec",
      files = shellspec_files,
    }
  end

  return nil
end

local function run_test_runner(project_root, runner)
  if runner.kind == "bats" then
    if vim.fn.executable("bats") ~= 1 then
      return nil, {
        code = "test_runner_not_found",
        message = "bats runner is not available.",
        phase = "tests",
      }
    end
    local dirs = runner.dirs
    local command = "bats " .. table.concat(vim.tbl_map(vim.fn.shellescape, dirs), " ")
    local result = shell_command(project_root, command)
    return result, result.ok and nil or {
      code = "tests_failed",
      message = "Bats test suite failed.",
      phase = "tests",
    }
  end

  if runner.kind == "shellspec" then
    if vim.fn.executable("shellspec") ~= 1 then
      return nil, {
        code = "test_runner_not_found",
        message = "shellspec runner is not available.",
        phase = "tests",
      }
    end
    local result = shell_command(project_root, "shellspec")
    return result, result.ok and nil or {
      code = "tests_failed",
      message = "ShellSpec suite failed.",
      phase = "tests",
    }
  end

  return nil, {
    code = "unsupported_project_shape",
    message = "Unsupported test runner shape.",
    phase = "tests",
  }
end

local function sem_evidence(project_root)
  if vim.fn.executable("sem") ~= 1 then
    return nil, {
      code = "sem_failed",
      message = "sem is not available.",
      phase = "sem",
    }
  end

  local result = shell_command(project_root, "sem --help")
  if not result.ok then
    return nil, {
      code = "sem_failed",
      message = "sem command failed.",
      phase = "sem",
    }
  end

  return result, nil
end

function M.generate_verify(workspace, opts)
  local include_tests = true
  local include_sem = false
  local timeout_ms = 30000
  if type(opts) == "table" then
    if opts.include_tests ~= nil then
      include_tests = opts.include_tests
    end
    if opts.include_sem ~= nil then
      include_sem = opts.include_sem
    end
    if opts.timeout_ms ~= nil then
      timeout_ms = opts.timeout_ms
    end
  end

  local requested_workspace = workspace or "."
  local phases = {
    discover = {},
    generate = {},
    derive_executable = {},
    shellcheck_generated = {},
    tests = {},
    sem = {},
  }
  local evidence = {}
  local started = vim.loop.hrtime()

  local discovered
  local ok, err = pcall(function()
    discovered = inspect_project(requested_workspace)
  end)
  if not ok then
    return error_result(requested_workspace, "project_discovery_failed", tostring(err), "discover", {
      phases = phases,
      evidence = evidence,
      path = requested_workspace,
    })
  end
  phases.discover = phase(true, {
    command = { repo_root() .. "/bin/bashly-inspect", requested_workspace },
    stdout = vim.json.encode(discovered),
    duration_ms = 0,
  })
  table.insert(evidence, {
    kind = "project_discovery",
    path = discovered.workspace,
    summary = "discovered project root and generated outputs",
  })
  if elapsed_ms(started) > timeout_ms then
    return timeout_result(discovered.workspace, "discover", elapsed_ms(started), timeout_ms, {
      phases = phases,
      evidence = evidence,
      path = discovered.workspace,
    })
  end

  local target_dir = discovered.target_dir or "."
  local target_dir_abs = discovered.workspace .. "/" .. target_dir
  vim.fn.mkdir(target_dir_abs, "p")

  local generate_env = ""
  if type(discovered.config_path) == "string" and discovered.config_path ~= "" then
    generate_env = "BASHLY_CONFIG_PATH=" .. vim.fn.shellescape(discovered.config_path) .. " "
  end
  local generate_result = shell_command(discovered.workspace, generate_env .. "bashly generate")
  phases.generate = phase(generate_result.ok, {
    command = { "bashly", "generate" },
    exit_code = generate_result.exit_code,
    stdout = generate_result.stdout,
    stderr = generate_result.stderr,
    duration_ms = generate_result.duration_ms,
  })
  table.insert(evidence, {
    kind = "generated_cli",
    path = discovered.generated_outputs and discovered.generated_outputs[1] or nil,
    command = { "bashly", "generate" },
    summary = generate_result.ok and "generated Bashly CLI" or "generation failed",
  })
  if not generate_result.ok then
    return error_result(discovered.workspace, "generate_failed", generate_result.stdout, "generate", {
      phases = phases,
      evidence = evidence,
      path = discovered.workspace,
    })
  end
  if elapsed_ms(started) > timeout_ms then
    return timeout_result(discovered.workspace, "generate", elapsed_ms(started), timeout_ms, {
      phases = phases,
      evidence = evidence,
      path = discovered.workspace,
    })
  end

  local executable_info, exec_error, exec_path = generated_executable_path(discovered.workspace, discovered.generated_outputs)
  if not executable_info then
    return error_result(discovered.workspace, exec_error, "generated executable missing or invalid", "derive_executable", {
      phases = phases,
      evidence = evidence,
      path = exec_path,
    })
  end
  phases.derive_executable = phase(true, {
    command = { "derive", executable_info.relative },
    stdout = executable_info.absolute,
    duration_ms = 0,
  })
  table.insert(evidence, {
    kind = "generated_executable",
    path = executable_info.relative,
    summary = "derived generated executable path",
  })
  if elapsed_ms(started) > timeout_ms then
    return timeout_result(discovered.workspace, "derive_executable", elapsed_ms(started), timeout_ms, {
      phases = phases,
      evidence = evidence,
      path = executable_info.absolute,
    })
  end

  local shellcheck_result = shell_command(discovered.workspace, "shellcheck -f gcc " .. vim.fn.shellescape(executable_info.absolute))
  phases.shellcheck_generated = phase(shellcheck_result.ok, {
    command = { "shellcheck", "-f", "gcc", executable_info.absolute },
    exit_code = shellcheck_result.exit_code,
    stdout = shellcheck_result.stdout,
    stderr = shellcheck_result.stderr,
    duration_ms = shellcheck_result.duration_ms,
  })
  table.insert(evidence, {
    kind = "shellcheck_generated",
    path = executable_info.relative,
    command = { "shellcheck", "-f", "gcc", executable_info.absolute },
    summary = shellcheck_result.ok and "shellcheck passed on generated executable" or "shellcheck failed on generated executable",
  })
  if shellcheck_result.exit_code ~= 0 then
    return error_result(discovered.workspace, "shellcheck_generated_failed", shellcheck_result.stdout, "shellcheck_generated", {
      phases = phases,
      evidence = evidence,
      path = executable_info.absolute,
    })
  end
  if elapsed_ms(started) > timeout_ms then
    return timeout_result(discovered.workspace, "shellcheck_generated", elapsed_ms(started), timeout_ms, {
      phases = phases,
      evidence = evidence,
      path = executable_info.absolute,
    })
  end

  local runner = detect_test_runner(discovered.workspace)
  if not include_tests then
    phases.tests = phase(true, {
      skipped = true,
      stdout = "skip: tests disabled by request",
      duration_ms = 0,
    })
  elseif runner == nil then
    phases.tests = phase(true, {
      skipped = true,
      stdout = "skip: no test runner fixtures detected",
      duration_ms = 0,
    })
  else
    local tests_result, tests_error = run_test_runner(discovered.workspace, runner)
    if tests_error then
      return error_result(discovered.workspace, tests_error.code, tests_error.message, tests_error.phase, {
        phases = phases,
        evidence = evidence,
        path = discovered.workspace,
      })
    end
    phases.tests = phase(tests_result.ok, {
      command = tests_result.command,
      exit_code = tests_result.exit_code,
      stdout = tests_result.stdout,
      stderr = tests_result.stderr,
      duration_ms = tests_result.duration_ms,
    })
    table.insert(evidence, {
      kind = "tests",
      command = tests_result.command,
      summary = tests_result.ok and "tests passed" or "tests failed",
    })
    if elapsed_ms(started) > timeout_ms then
      return timeout_result(discovered.workspace, "tests", elapsed_ms(started), timeout_ms, {
        phases = phases,
        evidence = evidence,
        path = discovered.workspace,
      })
    end
  end

  if include_sem then
    local sem_result, sem_error = sem_evidence(discovered.workspace)
    if sem_error then
      return error_result(discovered.workspace, sem_error.code, sem_error.message, sem_error.phase, {
        phases = phases,
        evidence = evidence,
        path = discovered.workspace,
      })
    end
    phases.sem = phase(sem_result.ok, {
      command = sem_result.command,
      exit_code = sem_result.exit_code,
      stdout = sem_result.stdout,
      stderr = sem_result.stderr,
      duration_ms = sem_result.duration_ms,
    })
    table.insert(evidence, {
      kind = "sem",
      command = sem_result.command,
      summary = "collected sem evidence",
    })
    if elapsed_ms(started) > timeout_ms then
      return timeout_result(discovered.workspace, "sem", elapsed_ms(started), timeout_ms, {
        phases = phases,
        evidence = evidence,
        path = discovered.workspace,
      })
    end
  else
    phases.sem = phase(true, {
      skipped = true,
      stdout = "skip: sem evidence not requested",
      duration_ms = 0,
    })
  end

  return {
    ok = true,
    project = {
      root = discovered.workspace,
      config = discovered.config_path,
      generated_executable = executable_info.relative,
    },
    phases = phases,
    evidence = evidence,
  }
end

function M.print_generate_verify(workspace, opts)
  io.write(vim.json.encode(M.generate_verify(workspace, opts)), "\n")
end

return M

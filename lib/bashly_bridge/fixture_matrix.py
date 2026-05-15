from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
BIN_DIR = REPO_ROOT / "bin"
FIXTURE_ROOT = REPO_ROOT / "fixtures"
RESULTS_DIR = REPO_ROOT / ".fixture-results"
PROJECT_BIN = BIN_DIR / "bashly-project"
VERIFY_BIN = BIN_DIR / "bashly-generate-verify"
APPLY_LUA = (
    'local apply = require("bashly_bridge.apply")\n'
    'local req = vim.json.decode(vim.env.BASHLY_APPLY_JSON)\n'
    'io.write(vim.json.encode(apply.apply_bashly_chunk(req)), "\\n")\n'
)
PUBLISH_LUA = (
    'local publisher = require("bashly_bridge.publish_diagnostics")\n'
    'local projection = vim.json.decode(vim.env.BASHLY_PROJECTION_JSON)\n'
    "for _, file in pairs((projection.source and projection.source.files) or {}) do\n"
    "  file.nvim = nil\n"
    "end\n"
    "publisher.publish(projection)\n"
    "local total = 0\n"
    "for _, file in pairs((projection.source and projection.source.files) or {}) do\n"
    "  local bufnr = file.nvim and file.nvim.bufnr\n"
    "  if not bufnr then\n"
    "    local path = file.path\n"
    "    if path and path ~= '' then\n"
    "      bufnr = vim.fn.bufnr((projection.workspace or vim.fn.getcwd()) .. '/' .. path, true)\n"
    "    end\n"
    "  end\n"
    "  if bufnr and bufnr > 0 then\n"
    "    total = total + #vim.diagnostic.get(bufnr, { namespace = publisher.namespace() })\n"
    "  end\n"
    "end\n"
    "io.write(tostring(total), '\\n')\n"
)


def run(cmd: list[str], cwd: Path | None = None, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    full_env = os.environ.copy()
    if env:
        full_env.update(env)
    return subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        env=full_env,
        text=True,
        capture_output=True,
        check=False,
    )


def run_json(cmd: list[str], cwd: Path | None = None, env: dict[str, str] | None = None) -> tuple[dict[str, Any] | None, dict[str, Any]]:
    proc = run(cmd, cwd=cwd, env=env)
    meta = {
        "command": cmd,
        "cwd": str(cwd) if cwd else None,
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
    }
    if proc.returncode != 0:
        return None, meta
    return json.loads(proc.stdout), meta


def fixture_expected_path(fixture_root: Path) -> Path:
    return fixture_root / "expected.json"


def load_expected(fixture_root: Path) -> dict[str, Any]:
    path = fixture_expected_path(fixture_root)
    if not path.exists():
        return {"name": fixture_root.name, "expect": {}}
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def copy_fixture(fixture_root: Path) -> Path:
    tmpdir = Path(tempfile.mkdtemp(prefix=f"bashly-matrix-{fixture_root.name}-"))
    destination = tmpdir / fixture_root.name
    shutil.copytree(fixture_root, destination)
    return destination


def strip_nvim_state(projection: dict[str, Any]) -> dict[str, Any]:
    cleaned = json.loads(json.dumps(projection))
    for file_data in (cleaned.get("source", {}).get("files", {}) or {}).values():
        if isinstance(file_data, dict):
            file_data.pop("nvim", None)
    return cleaned


def project_result(workspace: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    result, meta = run_json([str(PROJECT_BIN), str(workspace)])
    if result is None:
        return {"ok": False, "error": meta}, meta
    return result, meta


def generate_verify_result(workspace: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    result, meta = run_json([str(VERIFY_BIN), str(workspace)])
    if result is None:
        return {"ok": False, "error": meta}, meta
    return result, meta


def apply_result(workspace: Path, request: dict[str, Any], prelude: str = "") -> tuple[dict[str, Any], dict[str, Any]]:
    env = {
        "BASHLY_APPLY_JSON": json.dumps(request),
        "PYTHONPATH": f"{REPO_ROOT / 'lib'}{os.pathsep}{os.environ.get('PYTHONPATH', '')}",
    }
    script = tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False)
    try:
        script.write(prelude)
        script.write(APPLY_LUA)
        script.flush()
        script.close()
        proc = run(
            [
                "nvim",
                "--headless",
                "-n",
                "-u",
                "NONE",
                "--cmd",
                f"set rtp+={REPO_ROOT}",
                "-c",
                f"lua dofile('{script.name}')",
                "-c",
                "qa!",
            ],
            cwd=workspace,
            env=env,
        )
        meta = {
            "command": ["nvim", "--headless", "-n", "-u", "NONE"],
            "cwd": str(workspace),
            "returncode": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
        }
        if proc.returncode != 0:
            return {"ok": False, "error": meta}, meta
        return json.loads(proc.stdout), meta
    finally:
        try:
            os.unlink(script.name)
        except FileNotFoundError:
            pass


def publish_count(projection: dict[str, Any], workspace: Path) -> tuple[int, dict[str, Any]]:
    env = {
        "BASHLY_PROJECTION_JSON": json.dumps(strip_nvim_state(projection)),
    }
    script = tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False)
    try:
        script.write(PUBLISH_LUA)
        script.flush()
        script.close()
        proc = run(
            [
                "nvim",
                "--headless",
                "-n",
                "-u",
                "NONE",
                "--cmd",
                f"set rtp+={REPO_ROOT}",
                "-c",
                f"lua dofile('{script.name}')",
                "-c",
                "qa!",
            ],
            cwd=workspace,
            env=env,
        )
        meta = {
            "command": ["nvim", "--headless", "-n", "-u", "NONE"],
            "cwd": str(workspace),
            "returncode": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
        }
        if proc.returncode != 0:
            return -1, meta
        return int(proc.stdout.strip() or "0"), meta
    finally:
        try:
            os.unlink(script.name)
        except FileNotFoundError:
            pass


def observed_codes(diagnostics: list[dict[str, Any]]) -> list[str]:
    return [str(item.get("code", "")) for item in diagnostics]


def gate_blocking(gate: dict[str, Any] | None) -> bool:
    return bool(gate and gate.get("blocking_count", 0))


def project_codes(projection: dict[str, Any]) -> list[str]:
    return observed_codes(projection.get("diagnostics", []))


def argc_projection(projection: dict[str, Any]) -> dict[str, Any]:
    argc = projection.get("argc", {})
    return argc if isinstance(argc, dict) else {}


def argc_counts(projection: dict[str, Any]) -> dict[str, int]:
    argc = argc_projection(projection)
    facts = argc.get("facts", [])
    refs = argc.get("refs", [])
    resolved_refs = [ref for ref in refs if isinstance(ref, dict) and ref.get("resolved")]
    unresolved_refs = [ref for ref in refs if isinstance(ref, dict) and not ref.get("resolved")]
    return {
        "facts": len(facts) if isinstance(facts, list) else 0,
        "refs": len(refs) if isinstance(refs, list) else 0,
        "resolved_refs": len(resolved_refs),
        "unresolved_refs": len(unresolved_refs),
    }


def add_fixture_result(results: list[dict[str, Any]], result: dict[str, Any]) -> None:
    results.append(result)


def compare_expected_codes(expected: list[str], observed: list[str]) -> bool:
    return all(code in observed for code in expected)


def compare_gate(expected: bool | None, observed: bool) -> bool:
    if expected is None:
        return True
    return expected == observed


def compare_count(expected: int | None, observed: int) -> bool:
    if expected is None:
        return True
    return expected == observed


def make_summary_line(result: dict[str, Any]) -> str:
    status = "ok" if result.get("ok") else "fail"
    if result.get("skipped"):
        status = "skip"
    diagnostics = ",".join(result.get("observed", {}).get("diagnostics", [])) or "-"
    failures = ",".join(result.get("observed", {}).get("failures", [])) or "-"
    return f"{result['name']:<20} {status:<4} diag={diagnostics} fail={failures}"


def fixture_basic(fixture_root: Path) -> dict[str, Any]:
    expected = load_expected(fixture_root)
    temp_root = copy_fixture(fixture_root)
    projection, _ = project_result(temp_root)
    diagnostics = project_codes(projection)
    gate = gate_blocking(projection.get("gate"))
    publish_total = -1
    if all((temp_root / item.get("path", "")).exists() for item in projection.get("diagnostics", []) if item.get("path")):
        publish_total, _ = publish_count(projection, temp_root)

    hello_selector = projection.get("selectors", {}).get("source.handler.hello", {})
    source_path = hello_selector.get("path", "src/hello_command.sh")
    source_file = temp_root / source_path
    before_hash = source_file.read_bytes()

    skeleton_request = {
        "workspace": str(temp_root),
        "target": {"selector": "source.handler.hello"},
        "action": {"kind": "append", "content": "\n# fixture skeleton\n"},
    }
    skeleton_result, _ = apply_result(temp_root, skeleton_request)
    after_skeleton_hash = source_file.read_bytes()

    finalize_request = {
        "workspace": str(temp_root),
        "target": {"selector": "source.handler.hello"},
        "action": {"kind": "append", "content": "\n# fixture finalize\n"},
        "finalize": True,
        "pipeline": {"finalize": True, "normalize": True, "format": True, "write": True, "lint": True, "diagnostics_wait": True},
    }
    finalize_result, _ = apply_result(temp_root, finalize_request)
    after_finalize_hash = source_file.read_bytes()

    verify_result, _ = generate_verify_result(temp_root)

    ok = (
        compare_expected_codes(expected["expect"]["project"]["diagnostics"], diagnostics)
        and compare_gate(expected["expect"]["project"]["gate_blocking"], gate)
        and skeleton_result.get("ok") is True
        and before_hash == after_skeleton_hash
        and finalize_result.get("ok") is True
        and before_hash != after_finalize_hash
        and verify_result.get("ok") is True
        and (publish_total == len(projection.get("diagnostics", [])) or publish_total == 0)
    )

    return {
        "name": expected["name"],
        "ok": ok,
        "phases": {
            "project": projection,
            "apply": {"skeleton": skeleton_result},
            "finalize": finalize_result,
            "generate_verify": verify_result,
            "diagnostics": {"published_count": publish_total},
        },
        "expected": expected.get("expect", {}),
        "observed": {
            "diagnostics": diagnostics,
            "failures": [],
            "gate_blocking": gate,
        },
    }


def fixture_missing_source(fixture_root: Path) -> dict[str, Any]:
    expected = load_expected(fixture_root)
    temp_root = copy_fixture(fixture_root)
    projection, _ = project_result(temp_root)
    diagnostics = project_codes(projection)
    gate = gate_blocking(projection.get("gate"))
    ok = compare_expected_codes(expected["expect"]["project"]["diagnostics"], diagnostics) and compare_gate(
        expected["expect"]["project"]["gate_blocking"], gate
    )
    return {
        "name": expected["name"],
        "ok": ok,
        "phases": {"project": projection},
        "expected": expected.get("expect", {}),
        "observed": {
            "diagnostics": diagnostics,
            "failures": [],
            "gate_blocking": gate,
        },
    }


def fixture_unknown_args_ref(fixture_root: Path) -> dict[str, Any]:
    expected = load_expected(fixture_root)
    temp_root = copy_fixture(fixture_root)
    projection, _ = project_result(temp_root)
    diagnostics = project_codes(projection)
    gate = gate_blocking(projection.get("gate"))
    publish_total, _ = publish_count(projection, temp_root)
    ok = (
        compare_expected_codes(expected["expect"]["project"]["diagnostics"], diagnostics)
        and compare_gate(expected["expect"]["project"]["gate_blocking"], gate)
        and publish_total == len(projection.get("diagnostics", []))
    )
    return {
        "name": expected["name"],
        "ok": ok,
        "phases": {"project": projection, "diagnostics": {"published_count": publish_total}},
        "expected": expected.get("expect", {}),
        "observed": {
            "diagnostics": diagnostics,
            "failures": [],
            "gate_blocking": gate,
        },
    }


def fixture_unused_arg(fixture_root: Path) -> dict[str, Any]:
    expected = load_expected(fixture_root)
    temp_root = copy_fixture(fixture_root)
    projection, _ = project_result(temp_root)
    diagnostics = project_codes(projection)
    gate = gate_blocking(projection.get("gate"))
    publish_total, _ = publish_count(projection, temp_root)
    ok = (
        compare_expected_codes(expected["expect"]["project"]["diagnostics"], diagnostics)
        and compare_gate(expected["expect"]["project"]["gate_blocking"], gate)
        and publish_total == len(projection.get("diagnostics", []))
    )
    return {
        "name": expected["name"],
        "ok": ok,
        "phases": {"project": projection, "diagnostics": {"published_count": publish_total}},
        "expected": expected.get("expect", {}),
        "observed": {
            "diagnostics": diagnostics,
            "failures": [],
            "gate_blocking": gate,
        },
    }


def fixture_unused_flag(fixture_root: Path) -> dict[str, Any]:
    expected = load_expected(fixture_root)
    temp_root = copy_fixture(fixture_root)
    projection, _ = project_result(temp_root)
    diagnostics = project_codes(projection)
    gate = gate_blocking(projection.get("gate"))
    publish_total, _ = publish_count(projection, temp_root)
    ok = (
        compare_expected_codes(expected["expect"]["project"]["diagnostics"], diagnostics)
        and compare_gate(expected["expect"]["project"]["gate_blocking"], gate)
        and publish_total == len(projection.get("diagnostics", []))
    )
    return {
        "name": expected["name"],
        "ok": ok,
        "phases": {"project": projection, "diagnostics": {"published_count": publish_total}},
        "expected": expected.get("expect", {}),
        "observed": {
            "diagnostics": diagnostics,
            "failures": [],
            "gate_blocking": gate,
        },
    }


def fixture_argc_inner(fixture_root: Path) -> dict[str, Any]:
    expected = load_expected(fixture_root)
    temp_root = copy_fixture(fixture_root)
    projection, _ = project_result(temp_root)
    diagnostics = project_codes(projection)
    gate = gate_blocking(projection.get("gate"))
    argc = argc_counts(projection)
    argc_expect = expected.get("expect", {}).get("argc", {})
    ok = (
        compare_expected_codes(expected["expect"]["project"]["diagnostics"], diagnostics)
        and compare_gate(expected["expect"]["project"]["gate_blocking"], gate)
        and compare_count(argc_expect.get("facts"), argc["facts"])
        and compare_count(argc_expect.get("refs"), argc["refs"])
        and compare_count(argc_expect.get("resolved_refs"), argc["resolved_refs"])
    )
    return {
        "name": expected["name"],
        "ok": ok,
        "phases": {"project": projection},
        "expected": expected.get("expect", {}),
        "observed": {
            "diagnostics": diagnostics,
            "failures": [],
            "gate_blocking": gate,
        },
    }


def fixture_argc_unknown_ref(fixture_root: Path) -> dict[str, Any]:
    expected = load_expected(fixture_root)
    temp_root = copy_fixture(fixture_root)
    projection, _ = project_result(temp_root)
    diagnostics = project_codes(projection)
    gate = gate_blocking(projection.get("gate"))
    argc = argc_counts(projection)
    argc_expect = expected.get("expect", {}).get("argc", {})
    ok = (
        compare_expected_codes(expected["expect"]["project"]["diagnostics"], diagnostics)
        and compare_gate(expected["expect"]["project"]["gate_blocking"], gate)
        and compare_count(argc_expect.get("facts"), argc["facts"])
        and compare_count(argc_expect.get("refs"), argc["refs"])
        and compare_count(argc_expect.get("resolved_refs"), argc["resolved_refs"])
    )
    return {
        "name": expected["name"],
        "ok": ok,
        "phases": {"project": projection},
        "expected": expected.get("expect", {}),
        "observed": {
            "diagnostics": diagnostics,
            "failures": [],
            "gate_blocking": gate,
        },
    }


def fixture_apply_guard_stale(fixture_root: Path) -> dict[str, Any]:
    expected = load_expected(fixture_root)
    temp_root = copy_fixture(fixture_root)
    projection, _ = project_result(temp_root)
    selector = projection.get("selectors", {}).get("source.handler.hello", {})
    target_path = selector.get("path", "src/hello_command.sh")
    target_selector = "source.handler.hello"
    stale_failures: list[str] = []

    file_hash_case = copy_fixture(fixture_root)
    file_hash_proj, _ = project_result(file_hash_case)
    file_selector = file_hash_proj.get("selectors", {}).get("source.handler.hello", {})
    (file_hash_case / target_path).write_text(
        (file_hash_case / target_path).read_text(encoding="utf-8") + "\n# stale file hash\n",
        encoding="utf-8",
    )
    file_hash_request = {
        "workspace": str(file_hash_case),
        "target": {"selector": target_selector},
        "action": {"kind": "append", "content": "\n# stale\n"},
        "guard": {
            "file_sha256": file_selector.get("hashes", {}).get("file_sha256"),
        },
    }
    file_hash_result, _ = apply_result(file_hash_case, file_hash_request)
    if file_hash_result.get("error", {}).get("code") == "stale_file_hash":
        stale_failures.append("stale_file_hash")

    node_hash_case = copy_fixture(fixture_root)
    node_hash_proj, _ = project_result(node_hash_case)
    node_selector = node_hash_proj.get("selectors", {}).get("source.handler.hello", {})
    node_request = {
        "workspace": str(node_hash_case),
        "target": {"selector": target_selector},
        "action": {"kind": "append", "content": "\n# stale\n"},
        "guard": {
            "node_sha256": node_selector.get("hashes", {}).get("node_sha256"),
        },
    }
    node_prelude = (
        f"local path = vim.fn.fnameescape('{(node_hash_case / target_path).as_posix()}')\n"
        "vim.cmd('edit ' .. path)\n"
        "local bufnr = vim.api.nvim_get_current_buf()\n"
        "vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {\n"
        "  '#!/usr/bin/env bash',\n"
        "  \"echo 'node hash stale'\",\n"
        "})\n"
    )
    node_result, _ = apply_result(node_hash_case, node_request, prelude=node_prelude)
    if node_result.get("error", {}).get("code") == "stale_node_hash":
        stale_failures.append("stale_node_hash")

    tick_case = copy_fixture(fixture_root)
    tick_proj, _ = project_result(tick_case)
    tick_selector = tick_proj.get("selectors", {}).get("source.handler.hello", {})
    tick_request = {
        "workspace": str(tick_case),
        "target": {"selector": target_selector},
        "action": {"kind": "append", "content": "\n# stale\n"},
        "guard": {
            "changedtick": tick_selector.get("nvim", {}).get("changedtick"),
        },
    }
    tick_prelude = (
        f"local path = vim.fn.fnameescape('{(tick_case / target_path).as_posix()}')\n"
        "vim.cmd('edit ' .. path)\n"
        "local bufnr = vim.api.nvim_get_current_buf()\n"
        "local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)\n"
        "vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)\n"
    )
    tick_result, _ = apply_result(tick_case, tick_request, prelude=tick_prelude)
    if tick_result.get("error", {}).get("code") == "stale_changedtick":
        stale_failures.append("stale_changedtick")

    expected_failures = expected.get("expect", {}).get("apply", {}).get("failures", [])
    ok = compare_expected_codes(expected_failures, stale_failures)
    return {
        "name": expected["name"],
        "ok": ok,
        "phases": {
            "project": projection,
            "apply": {
                "stale_file_hash": file_hash_result,
                "stale_node_hash": node_result,
                "stale_changedtick": tick_result,
            },
        },
        "expected": expected.get("expect", {}),
        "observed": {
            "diagnostics": project_codes(projection),
            "failures": stale_failures,
            "gate_blocking": gate_blocking(projection.get("gate")),
        },
    }


def fixture_placeholder(name: str) -> dict[str, Any]:
    return {
        "name": name,
        "ok": True,
        "skipped": True,
        "reason": "adapter not implemented yet",
        "phases": {},
        "expected": {},
        "observed": {
            "diagnostics": [],
            "failures": [],
            "gate_blocking": False,
        },
    }


def run_matrix() -> dict[str, Any]:
    results: list[dict[str, Any]] = []
    available = {
        "bashly-basic": fixture_basic,
        "missing-source": fixture_missing_source,
        "unknown-args-ref": fixture_unknown_args_ref,
        "unused-arg": fixture_unused_arg,
        "unused-flag": fixture_unused_flag,
        "argc-inner": fixture_argc_inner,
        "argc-unknown-ref": fixture_argc_unknown_ref,
        "apply-guard-stale": fixture_apply_guard_stale,
    }

    for name, runner in available.items():
        fixture_root = FIXTURE_ROOT / name
        if not fixture_root.exists():
            add_fixture_result(results, {
                "name": name,
                "ok": False,
                "skipped": True,
                "reason": "fixture directory missing",
                "phases": {},
                "expected": {},
                "observed": {
                    "diagnostics": [],
                    "failures": [],
                    "gate_blocking": False,
                },
            })
            continue
        add_fixture_result(results, runner(fixture_root))

    for placeholder in ("bash-ast-parse-error",):
        add_fixture_result(results, fixture_placeholder(placeholder))

    ok = all(item.get("ok") for item in results)
    matrix = {"ok": ok, "fixtures": results}
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    (RESULTS_DIR / "matrix.json").write_text(json.dumps(matrix, indent=2, sort_keys=True), encoding="utf-8")
    (RESULTS_DIR / "matrix.md").write_text(render_markdown(matrix), encoding="utf-8")
    for item in results:
        (RESULTS_DIR / f"{item['name']}.json").write_text(
            json.dumps(item, indent=2, sort_keys=True),
            encoding="utf-8",
        )
    return matrix


def render_markdown(matrix: dict[str, Any]) -> str:
    lines = ["# Bashly Fixture Matrix", ""]
    lines.append("| Fixture | Status | Diagnostics | Failures | Gate |")
    lines.append("| --- | --- | --- | --- | --- |")
    for fixture in matrix.get("fixtures", []):
        status = "skipped" if fixture.get("skipped") else ("ok" if fixture.get("ok") else "fail")
        diagnostics = ", ".join(fixture.get("observed", {}).get("diagnostics", [])) or "-"
        failures = ", ".join(fixture.get("observed", {}).get("failures", [])) or "-"
        gate = "blocking" if fixture.get("observed", {}).get("gate_blocking") else "green"
        lines.append(f"| {fixture['name']} | {status} | {diagnostics} | {failures} | {gate} |")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    matrix = run_matrix()
    sys.stdout.write(json.dumps(matrix, indent=2, sort_keys=True) + "\n")
    return 0 if matrix.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())

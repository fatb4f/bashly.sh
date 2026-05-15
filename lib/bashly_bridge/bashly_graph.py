from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

import yaml

from .discovery import DiscoveryError, discover_project


class GraphError(RuntimeError):
    pass


def _load_yaml(path: Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = yaml.safe_load(handle)
    except FileNotFoundError as exc:
        raise GraphError(f"missing file: {path}") from exc
    except yaml.YAMLError as exc:
        raise GraphError(f"failed to parse YAML: {path}") from exc
    return data or {}


def _sha256_text(text: bytes) -> str:
    return f"sha256:{hashlib.sha256(text).hexdigest()}"


def _sha256_file(path: Path) -> str:
    return _sha256_text(path.read_bytes())


def _relative_to(root: Path, candidate: Path) -> str:
    try:
        return candidate.relative_to(root).as_posix()
    except ValueError:
        return candidate.as_posix()


def _command_selector_id(path: list[str]) -> str:
    if not path:
        return "bashly.command.root"
    return "bashly.command." + ".".join(path)


def _arg_selector_id(command_path: list[str], arg_name: str) -> str:
    return f"bashly.arg.{'.'.join(command_path) if command_path else 'root'}.{arg_name}"


def _flag_selector_id(command_path: list[str], flag_name: str) -> str:
    return f"bashly.flag.{'.'.join(command_path) if command_path else 'root'}.{flag_name}"


def _env_selector_id(command_path: list[str], env_name: str) -> str:
    normalized = env_name.upper()
    return f"bashly.env.{'.'.join(command_path) if command_path else 'root'}.{normalized}"


def _source_file_for_command(source_dir: Path, command_path: list[str]) -> Path:
    if not command_path:
        return source_dir / "root_command.sh"
    return source_dir / f"{'_'.join(command_path)}_command.sh"


def _selector_record(selector_id: str, kind: str, path: str, children: list[str], file_sha256: str | None) -> dict[str, Any]:
    record: dict[str, Any] = {
        "id": selector_id,
        "kind": kind,
        "path": path,
        "children": children,
    }
    if file_sha256:
        record["hashes"] = {"file_sha256": file_sha256}
    return record


def _merge_unique(items: list[str], seen: set[str], selector_id: str) -> None:
    if selector_id in seen:
        return
    seen.add(selector_id)
    items.append(selector_id)


def _command_name(node: dict[str, Any], fallback: str) -> str:
    name = str(node.get("name") or fallback).strip()
    return name or fallback


def _project_command(
    *,
    workspace: Path,
    source_dir: Path,
    node: dict[str, Any],
    command_path: list[str],
    inherited_flag_ids: list[str],
    inherited_env_ids: list[str],
    commands: list[dict[str, Any]],
    selectors: dict[str, dict[str, Any]],
    diagnostics: list[dict[str, Any]],
) -> None:
    command_name = _command_name(node, "root" if not command_path else f"command-{len(commands)}")
    selector_id = _command_selector_id(command_path)
    source_file = _source_file_for_command(source_dir, command_path)
    source_file_rel = _relative_to(workspace, source_file)
    file_sha256 = _sha256_file(source_file) if source_file.is_file() else None

    if not source_file.is_file():
        diagnostics.append(
            {
                "source": "bashly_graph",
                "code": "BASHLY_SOURCE_FILE_MISSING",
                "severity": "error",
                "message": f"expected Bashly source file is missing: {source_file_rel}",
                "path": source_file_rel,
                "selector": selector_id,
            }
        )

    selectors[selector_id] = _selector_record(
        selector_id,
        "bashly_command",
        source_file_rel,
        [],
        file_sha256,
    )

    local_arg_ids: list[str] = []
    local_flag_ids: list[str] = []
    local_env_ids: list[str] = []
    selector_children: list[str] = []

    for arg in node.get("args") or []:
        arg_name = str(arg.get("name", "")).strip()
        if not arg_name:
            continue
        arg_id = _arg_selector_id(command_path, arg_name)
        local_arg_ids.append(arg_id)
        selector_children.append(arg_id)
        selectors[arg_id] = _selector_record(
            arg_id,
            "bashly_arg",
            source_file_rel,
            [],
            file_sha256,
        )

    command_flags = list(inherited_flag_ids)
    command_envs = list(inherited_env_ids)
    seen_flag_ids: set[str] = set(command_flags)
    seen_env_ids: set[str] = set(command_envs)

    for flag in node.get("flags") or []:
        flag_name = str(flag.get("long") or flag.get("short") or "").strip()
        if not flag_name:
            continue
        flag_id = _flag_selector_id(command_path, flag_name)
        local_flag_ids.append(flag_id)
        selector_children.append(flag_id)
        selectors[flag_id] = _selector_record(
            flag_id,
            "bashly_flag",
            source_file_rel,
            [],
            file_sha256,
        )
        _merge_unique(command_flags, seen_flag_ids, flag_id)

    for env in node.get("environment_variables") or []:
        env_name = str(env.get("name", "")).strip()
        if not env_name:
            continue
        env_id = _env_selector_id(command_path, env_name)
        local_env_ids.append(env_id)
        selector_children.append(env_id)
        selectors[env_id] = _selector_record(
            env_id,
            "bashly_env",
            source_file_rel,
            [],
            file_sha256,
        )
        _merge_unique(command_envs, seen_env_ids, env_id)

    command_record = {
        "id": selector_id,
        "name": command_name,
        "path": list(command_path),
        "source_file": source_file_rel,
        "handler_selector": None,
        "flags": command_flags + [flag_id for flag_id in local_flag_ids if flag_id not in command_flags],
        "args": local_arg_ids,
        "env": command_envs + [env_id for env_id in local_env_ids if env_id not in command_envs],
    }
    commands.append(command_record)

    child_command_ids: list[str] = []
    for index, child in enumerate(node.get("commands") or []):
        child_name = _command_name(child, f"command-{index}")
        child_path = command_path + [child_name]
        child_id = _command_selector_id(child_path)
        child_command_ids.append(child_id)
        _project_command(
            workspace=workspace,
            source_dir=source_dir,
            node=child,
            command_path=child_path,
            inherited_flag_ids=command_flags,
            inherited_env_ids=command_envs,
            commands=commands,
            selectors=selectors,
            diagnostics=diagnostics,
        )

    selectors[selector_id]["children"] = selector_children + child_command_ids


def build_graph_projection(workspace: str | Path = ".") -> dict[str, Any]:
    discovered = discover_project(workspace)
    workspace_root = Path(discovered["workspace"])
    source_dir = (workspace_root / discovered["source_dir"]).resolve()
    config_path = (workspace_root / discovered["config_path"]).resolve()

    config = _load_yaml(config_path)
    model_hash = _sha256_file(config_path)

    commands: list[dict[str, Any]] = []
    selectors: dict[str, dict[str, Any]] = {}
    diagnostics: list[dict[str, Any]] = []

    _project_command(
        workspace=workspace_root,
        source_dir=source_dir,
        node=config,
        command_path=[],
        inherited_flag_ids=[],
        inherited_env_ids=[],
        commands=commands,
        selectors=selectors,
        diagnostics=diagnostics,
    )

    return {
        "schema_version": 1,
        "workspace": workspace_root.as_posix(),
        "bashly": {
            "config_path": discovered["config_path"],
            "model_hash": model_hash,
            "commands": commands,
        },
        "selectors": selectors,
        "diagnostics": diagnostics,
    }


def build_graph_projection_json(workspace: str | Path = ".") -> str:
    return json.dumps(build_graph_projection(workspace), indent=2, sort_keys=False)

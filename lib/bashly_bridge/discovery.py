from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import yaml

SETTINGS_FILENAMES = ("bashly-settings.yml", "settings.yml")
TEST_DIR_NAMES = ("test", "spec")


class DiscoveryError(RuntimeError):
    pass


def _load_yaml(path: Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = yaml.safe_load(handle)
    except FileNotFoundError as exc:
        raise DiscoveryError(f"missing file: {path}") from exc
    except yaml.YAMLError as exc:
        raise DiscoveryError(f"failed to parse YAML: {path}") from exc
    return data or {}


def _relativize(root: Path, candidate: Path) -> str:
    try:
        return candidate.relative_to(root).as_posix()
    except ValueError:
        return candidate.as_posix()


def _find_project_root(start: Path) -> tuple[Path, Path]:
    current = start
    for candidate in [current, *current.parents]:
        for settings_name in SETTINGS_FILENAMES:
            settings_path = candidate / settings_name
            if settings_path.is_file():
                return candidate, settings_path
    raise DiscoveryError(
        "could not find a Bashly project root with bashly-settings.yml or settings.yml"
    )


def _resolve_source_dir(project_root: Path, settings: dict[str, Any]) -> Path:
    source_dir = Path(settings.get("source_dir", "src"))
    if source_dir.is_absolute():
        return source_dir.resolve()
    return (project_root / source_dir).resolve()


def _resolve_config_path(project_root: Path, source_dir: Path, settings: dict[str, Any]) -> Path:
    config_path = Path(settings.get("config_path", "bashly.yml"))
    if config_path.is_absolute():
        return config_path.resolve()

    source_candidate = (source_dir / config_path).resolve()
    if source_candidate.is_file():
        return source_candidate

    project_candidate = (project_root / config_path).resolve()
    if project_candidate.is_file():
        return project_candidate

    return source_candidate


def _resolve_target_dir(project_root: Path, settings: dict[str, Any]) -> Path:
    target_dir = Path(settings.get("target_dir", "bin"))
    if target_dir.is_absolute():
        return target_dir.resolve()
    return (project_root / target_dir).resolve()


def _derive_executable_candidates(project_root: Path, target_dir: Path, cli_name: str) -> list[str]:
    if not cli_name:
        return []
    executable = target_dir / cli_name
    return [_relativize(project_root, executable)]


def _detect_test_dirs(project_root: Path) -> list[str]:
    return [
        name
        for name in TEST_DIR_NAMES
        if (project_root / name).is_dir()
    ]


def discover_project(workspace: str | Path = ".") -> dict[str, Any]:
    workspace_path = Path(workspace).expanduser().resolve()
    project_root, settings_path = _find_project_root(workspace_path)
    settings = _load_yaml(settings_path)

    source_dir = _resolve_source_dir(project_root, settings)
    config_path = _resolve_config_path(project_root, source_dir, settings)
    target_dir = _resolve_target_dir(project_root, settings)
    cli_config = _load_yaml(config_path)
    cli_name = str(cli_config.get("name", project_root.name)).strip()

    return {
        "workspace": project_root.as_posix(),
        "settings_file": _relativize(project_root, settings_path),
        "source_dir": _relativize(project_root, source_dir),
        "config_path": _relativize(project_root, config_path),
        "target_dir": _relativize(project_root, target_dir),
        "generated_outputs": _derive_executable_candidates(project_root, target_dir, cli_name),
        "test_dirs": _detect_test_dirs(project_root),
    }


def discover_project_json(workspace: str | Path = ".") -> str:
    return json.dumps(discover_project(workspace), indent=2, sort_keys=False)

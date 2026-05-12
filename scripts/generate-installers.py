from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent

ASSETS = [
    ("agents/memory-curator.md", "agents/memory-curator.md"),
    ("agents/memory-recall.md", "agents/memory-recall.md"),
    ("commands/remember-feature.md", "commands/remember-feature.md"),
    ("commands/recall-feature.md", "commands/recall-feature.md"),
    ("commands/review-memory.md", "commands/review-memory.md"),
    (
        "scripts/bootstrap-project.ps1",
        "opencode-memory-kit/scripts/bootstrap-project.ps1",
    ),
    (
        "scripts/bootstrap-project.sh",
        "opencode-memory-kit/scripts/bootstrap-project.sh",
    ),
    ("templates/project/AGENTS.md", "opencode-memory-kit/templates/project/AGENTS.md"),
    (
        "templates/project/AGENTS.memory.md",
        "opencode-memory-kit/templates/project/AGENTS.memory.md",
    ),
    (
        "templates/project/docs/ai-memory/INDEX.md",
        "opencode-memory-kit/templates/project/docs/ai-memory/INDEX.md",
    ),
    (
        "templates/project/docs/ai-memory/decisions.md",
        "opencode-memory-kit/templates/project/docs/ai-memory/decisions.md",
    ),
    (
        "templates/project/docs/ai-memory/troubleshooting.md",
        "opencode-memory-kit/templates/project/docs/ai-memory/troubleshooting.md",
    ),
    (
        "templates/project/docs/ai-memory/features/README.md",
        "opencode-memory-kit/templates/project/docs/ai-memory/features/README.md",
    ),
]


def read_asset(relative_path: str) -> str:
    return (REPO_ROOT / relative_path).read_text(encoding="utf-8").rstrip("\n")


def shell_marker(relative_path: str, content: str) -> str:
    marker = "EOF_" + re.sub(r"[^A-Z0-9]+", "_", relative_path.upper()).strip("_")
    while f"\n{marker}\n" in content or content.endswith(f"\n{marker}"):
        marker += "_X"
    return marker


def generate_install_ps1() -> str:
    parts = [
        "param(",
        '    [string]$ConfigDir = (Join-Path $HOME ".config\\opencode"),',
        "    [switch]$Force",
        ")",
        "",
        '$ErrorActionPreference = "Stop"',
        "",
        "function Write-Utf8NoBomFile {",
        "    param(",
        "        [string]$Path,",
        "        [string]$Content",
        "    )",
        "",
        "    $encoding = New-Object System.Text.UTF8Encoding($false)",
        "    [System.IO.File]::WriteAllText($Path, $Content, $encoding)",
        "}",
        "",
        "function Install-Asset {",
        "    param(",
        "        [string]$RelativePath,",
        "        [string]$Content",
        "    )",
        "",
        "    $destination = Join-Path $ConfigDir $RelativePath",
        "    $destinationDir = Split-Path -Parent $destination",
        "",
        "    if ($destinationDir -and -not (Test-Path $destinationDir)) {",
        "        New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null",
        "    }",
        "",
        "    $exists = Test-Path $destination",
        "    if ($exists -and -not $Force) {",
        '        Write-Host "Skipped $RelativePath"',
        "        return",
        "    }",
        "",
        "    Write-Utf8NoBomFile -Path $destination -Content $Content",
        "    if ($exists) {",
        '        Write-Host "Updated $RelativePath"',
        "    }",
        "    else {",
        '        Write-Host "Created $RelativePath"',
        "    }",
        "}",
        "",
        "$assets = @(",
    ]

    for index, (source_path, install_path) in enumerate(ASSETS):
        content = read_asset(source_path)
        parts.extend(
            [
                "    @{",
                f'        Path = "{install_path.replace("/", "\\")}"',
                "        Content = @'",
                content,
                "'@",
                f"    }}{',' if index < len(ASSETS) - 1 else ''}",
            ]
        )

    parts.extend(
        [
            ")",
            "",
            "foreach ($asset in $assets) {",
            "    Install-Asset -RelativePath $asset.Path -Content $asset.Content",
            "}",
            "",
            '$bootstrapPath = Join-Path $ConfigDir "opencode-memory-kit\\scripts\\bootstrap-project.ps1"',
            "",
            'Write-Host ""',
            'Write-Host "OpenCode memory kit installed under $ConfigDir"',
            'Write-Host "Installed into default OpenCode locations:"',
            'Write-Host "  - agents/"',
            'Write-Host "  - commands/"',
            'Write-Host "  - opencode-memory-kit/"',
            'Write-Host ""',
            'Write-Host "Commands now available: /remember-feature, /recall-feature, and /review-memory"',
            'Write-Host "Bootstrap or refresh a repo with:"',
            "Write-Host ('  powershell -ExecutionPolicy Bypass -File \"{0}\" -Target .' -f $bootstrapPath)",
            'Write-Host "Rerun the same bootstrap command later to refresh managed instructions without overwriting saved memory notes."',
        ]
    )

    return "\n".join(parts) + "\n"


def generate_install_sh() -> str:
    parts = [
        "#!/usr/bin/env sh",
        "set -eu",
        "",
        'config_dir="${HOME}/.config/opencode"',
        'force="0"',
        "",
        'while [ "$#" -gt 0 ]; do',
        '  case "$1" in',
        "    --force)",
        '      force="1"',
        "      ;;",
        "    --config-dir)",
        "      shift",
        '      config_dir="$1"',
        "      ;;",
        "    -h|--help)",
        "      printf '%s\\n' \"Usage: sh install.sh [--config-dir DIR] [--force]\"",
        "      exit 0",
        "      ;;",
        "    *)",
        "      printf '%s\\n' \"Unknown argument: $1\" >&2",
        "      exit 1",
        "      ;;",
        "  esac",
        "  shift",
        "done",
        "",
        "write_file() {",
        '  relative_path="$1"',
        '  destination="$config_dir/$relative_path"',
        "",
        '  mkdir -p "$(dirname "$destination")"',
        "",
        '  if [ -f "$destination" ] && [ "$force" != "1" ]; then',
        "    printf '%s\\n' \"Skipped $relative_path\"",
        "    cat > /dev/null",
        "    return 0",
        "  fi",
        "",
        '  if [ -f "$destination" ]; then',
        '    status="Updated"',
        "  else",
        '    status="Created"',
        "  fi",
        "",
        '  cat > "$destination"',
        "  printf '%s\\n' \"$status $relative_path\"",
        "}",
    ]

    for source_path, install_path in ASSETS:
        content = read_asset(source_path)
        marker = shell_marker(install_path, content)
        parts.extend(
            [
                "",
                f"write_file \"{install_path}\" <<'{marker}'",
                content,
                marker,
            ]
        )

    parts.extend(
        [
            "",
            'bootstrap_path="$config_dir/opencode-memory-kit/scripts/bootstrap-project.sh"',
            "",
            "printf '\\n'",
            "printf '%s\\n' \"OpenCode memory kit installed under $config_dir\"",
            "printf '%s\\n' \"Installed into default OpenCode locations:\"",
            "printf '%s\\n' \"  - agents/\"",
            "printf '%s\\n' \"  - commands/\"",
            "printf '%s\\n' \"  - opencode-memory-kit/\"",
            "printf '\\n'",
            "printf '%s\\n' \"Commands now available: /remember-feature, /recall-feature, and /review-memory\"",
            "printf '%s\\n' \"Bootstrap or refresh a repo with:\"",
            'printf \'%s\\n\' "  sh \\"$bootstrap_path\\" ."',
            "printf '%s\\n' \"Rerun the same bootstrap command later to refresh managed instructions without overwriting saved memory notes.\"",
        ]
    )

    return "\n".join(parts) + "\n"


def main() -> None:
    (REPO_ROOT / "install.ps1").write_text(
        generate_install_ps1(), encoding="utf-8", newline="\n"
    )
    (REPO_ROOT / "install.sh").write_text(
        generate_install_sh(), encoding="utf-8", newline="\n"
    )


if __name__ == "__main__":
    main()

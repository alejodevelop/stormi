#!/usr/bin/env sh
set -eu

config_dir="${HOME}/.config/opencode"
force="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="1"
      ;;
    --config-dir)
      shift
      config_dir="$1"
      ;;
    -h|--help)
      printf '%s\n' "Usage: sh scripts/install-global.sh [--config-dir DIR] [--force]"
      exit 0
      ;;
    *)
      printf '%s\n' "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")
kit_home="$config_dir/opencode-memory-kit"

copy_managed_file() {
  source_path="$1"
  destination="$2"

  mkdir -p "$(dirname "$destination")"

  if [ -f "$destination" ] && [ "$force" != "1" ]; then
    printf '%s\n' "Skipped $destination"
    return
  fi

  if [ -f "$destination" ]; then
    cp "$source_path" "$destination"
    printf '%s\n' "Updated $destination"
  else
    cp "$source_path" "$destination"
    printf '%s\n' "Created $destination"
  fi
}

find "$repo_root/agents" -maxdepth 1 -type f | sort | while IFS= read -r source_path; do
  destination="$config_dir/agents/$(basename "$source_path")"
  copy_managed_file "$source_path" "$destination"
done

find "$repo_root/commands" -maxdepth 1 -type f | sort | while IFS= read -r source_path; do
  destination="$config_dir/commands/$(basename "$source_path")"
  copy_managed_file "$source_path" "$destination"
done

find "$repo_root/templates" -type f | sort | while IFS= read -r source_path; do
  relative_path=${source_path#"$repo_root/"}
  destination="$kit_home/$relative_path"
  copy_managed_file "$source_path" "$destination"
done

find "$repo_root/scripts" -type f ! -path '*/__pycache__/*' ! -name '*.pyc' | sort | while IFS= read -r source_path; do
  relative_path=${source_path#"$repo_root/"}
  destination="$kit_home/$relative_path"
  copy_managed_file "$source_path" "$destination"
done

printf '\n'
printf '%s\n' "OpenCode memory kit installed under $config_dir"
printf '%s\n' "Commands now available: /remember-feature, /recall-feature, and /review-memory"
printf '%s\n' "Bootstrap or refresh a repo with:"
printf '%s\n' "  sh \"$kit_home/scripts/bootstrap-project.sh\" ."
printf '%s\n' "Rerun the same bootstrap command later to refresh managed instructions without overwriting saved memory notes."

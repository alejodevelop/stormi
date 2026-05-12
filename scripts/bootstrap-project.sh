#!/usr/bin/env sh
set -eu

target="."
force="0"
start_marker="<!-- opencode-memory-kit:start -->"
end_marker="<!-- opencode-memory-kit:end -->"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="1"
      ;;
    -h|--help)
      printf '%s\n' "Usage: sh scripts/bootstrap-project.sh [target-dir] [--force]"
      exit 0
      ;;
    *)
      target="$1"
      ;;
  esac
  shift
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")
template_root="$repo_root/templates/project"
docs_template_root="$template_root/docs"
full_agents_template="$template_root/AGENTS.md"
append_agents_template="$template_root/AGENTS.memory.md"

sync_agents_file() {
  file_path="$1"
  use_crlf="0"
  cr=$(printf '\r')

  if grep -q "$cr" "$file_path"; then
    use_crlf="1"
  fi

  start_count=$(grep -F -c "$start_marker" "$file_path" || true)
  end_count=$(grep -F -c "$end_marker" "$file_path" || true)

  if [ "$start_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
    sync_mode="append"
  elif [ "$start_count" -eq 1 ] && [ "$end_count" -eq 1 ]; then
    start_line=$(awk -v marker="$start_marker" 'index($0, marker) { print NR; exit }' "$file_path")
    end_line=$(awk -v marker="$end_marker" 'index($0, marker) { print NR; exit }' "$file_path")

    if [ "$start_line" -ge "$end_line" ]; then
      printf '%s\n' "Invalid AGENTS.md markers in $file_path. Fix the marker order manually." >&2
      exit 1
    fi

    sync_mode="replace"
  else
    printf '%s\n' "Invalid AGENTS.md markers in $file_path. Expected exactly one managed block or none." >&2
    exit 1
  fi

  tmp_file=$(mktemp)

  if [ "$sync_mode" = "replace" ]; then
    awk -v use_crlf="$use_crlf" -v start="$start_marker" -v end="$end_marker" -v replacement="$append_agents_template" '
      BEGIN {
        ORS = (use_crlf == "1") ? "\r\n" : "\n"
      }

      function print_replacement(   line) {
        while ((getline line < replacement) > 0) {
          sub(/\r$/, "", line)
          print line
        }
        close(replacement)
      }

      {
        sub(/\r$/, "", $0)

        if (!in_block && index($0, start)) {
          print_replacement()
          in_block = 1
          next
        }

        if (in_block) {
          if (index($0, end)) {
            in_block = 0
          }
          next
        }

        print $0
      }
    ' "$file_path" > "$tmp_file"
  else
    awk -v use_crlf="$use_crlf" -v replacement="$append_agents_template" '
      BEGIN {
        ORS = (use_crlf == "1") ? "\r\n" : "\n"
      }

      function print_replacement(   line) {
        while ((getline line < replacement) > 0) {
          sub(/\r$/, "", line)
          print line
        }
        close(replacement)
      }

      {
        sub(/\r$/, "", $0)
        print $0
      }

      END {
        if (NR > 0) {
          print ""
        }
        print_replacement()
      }
    ' "$file_path" > "$tmp_file"
  fi

  if cmp -s "$file_path" "$tmp_file"; then
    rm -f "$tmp_file"
    printf '%s\n' "AGENTS.md already up to date"
    return
  fi

  mv "$tmp_file" "$file_path"

  if [ "$sync_mode" = "replace" ]; then
    printf '%s\n' "Updated AGENTS.md (refreshed managed memory workflow block)"
  else
    printf '%s\n' "Updated AGENTS.md (appended memory workflow block)"
  fi
}

if [ ! -d "$target" ]; then
  printf '%s\n' "Target directory does not exist: $target" >&2
  exit 1
fi

target=$(CDPATH= cd -- "$target" && pwd)
target_agents="$target/AGENTS.md"

if [ -f "$target_agents" ]; then
  sync_agents_file "$target_agents"
else
  cp "$full_agents_template" "$target_agents"
  printf '%s\n' "Created AGENTS.md"
fi

find "$docs_template_root" -type f | sort | while IFS= read -r source_path; do
  relative_path=${source_path#"$template_root/"}
  destination="$target/$relative_path"
  destination_dir=$(dirname "$destination")

  mkdir -p "$destination_dir"

  if [ -f "$destination" ] && [ "$force" != "1" ]; then
    printf '%s\n' "Skipped $relative_path"
    continue
  fi

  if [ -f "$destination" ]; then
    cp "$source_path" "$destination"
    printf '%s\n' "Updated $relative_path"
  else
    cp "$source_path" "$destination"
    printf '%s\n' "Created $relative_path"
  fi
done

printf '\n'
printf '%s\n' "Project memory workflow is ready in $target"
printf '%s\n' "Next steps:"
printf '%s\n' "  1. Open the project in OpenCode"
printf '%s\n' "  2. Work as usual with plan and build"
printf '%s\n' "  3. Let OpenCode delegate broad reading to explore and multi-step execution to general"
printf '%s\n' "  4. Run /remember-feature <slug> when a feature is accepted"
printf '%s\n' "  5. Run /recall-feature <query> in future sessions"
printf '%s\n' "  6. Run /review-memory [scope] after large refactors or removals"
printf '%s\n' "You can rerun this same bootstrap command later to refresh managed AGENTS.md instructions."
printf '%s\n' "Saved notes under docs/ai-memory/ stay intact unless you use --force."

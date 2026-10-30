#!/usr/bin/env bash
# Checks every integration folder of this repository against
# docs/integration-manifest.md.
#
# Usage: tools/check-integrations.sh [REPOSITORY_ROOT]
# Exit 0 when every integration passes, 1 when any rule fails, 2 on usage.

set -euo pipefail

if [ "$#" -gt 1 ]; then
  echo "usage: tools/check-integrations.sh [REPOSITORY_ROOT]" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is needed; install it, then run again" >&2
  exit 2
fi

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
if [ ! -d "$root" ]; then
  echo "not a directory: $root" >&2
  exit 2
fi

failures=0
integrations=0

fail() {
  echo "FAIL $1: $2"
  failures=$((failures + 1))
}

# Patterns of values that look like a secret: GitHub token prefixes, other
# common key formats, PEM blocks, and long unbroken runs of key characters.
secret_pattern='(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY|[A-Za-z0-9_]{40,})'

# Prints the problems of one manifest, one per line; prints nothing when valid.
manifest_problems() {
  jq -r --arg secret "$secret_pattern" '
    def nonempty_string: type == "string" and (gsub("\\s"; "") | length) > 0;
    if type != "object" then "the manifest is not a JSON object"
    else
      (keys_unsorted - ["name", "description", "token", "prerequisites"]
        | .[] | "unknown field: \(.)"),
      (if has("name") | not then "missing required field: name"
       elif (.name | nonempty_string) | not then "name must be a non-empty string"
       else empty end),
      (if has("description") | not then "missing required field: description"
       elif (.description | nonempty_string) | not then "description must be a non-empty string"
       else empty end),
      (if has("token") | not then empty
       elif (.token | type) != "object" then "token must be an object"
       else
         (.token | keys_unsorted - ["help"] | .[] | "unknown field: token.\(.)"),
         (if (.token | has("help")) | not then "missing required field: token.help"
          elif (.token.help | nonempty_string) | not then "token.help must be a non-empty string"
          else empty end)
       end),
      (if has("prerequisites") | not then empty
       elif (.prerequisites | type) != "array" then "prerequisites must be an array of tool names"
       else
         .prerequisites[]
         | select((type == "string" and test("^[A-Za-z0-9._+-]+$")) | not)
         | "prerequisites entry is not a tool name: \(tojson)"
       end),
      ([.. | strings | select(test($secret))] | if length > 0
        then "a value looks like a secret (no secret may be in a manifest)"
        else empty end)
    end
  ' "$1"
}

for dir in "$root"/*/; do
  [ -d "$dir" ] || continue
  folder="$(basename "$dir")"
  has_skill=no
  has_manifest=no
  [ -f "$dir/SKILL.md" ] && has_skill=yes
  [ -f "$dir/integration.json" ] && has_manifest=yes

  if [ "$has_skill" = no ] && [ "$has_manifest" = no ]; then
    continue
  fi
  integrations=$((integrations + 1))

  if [ "$has_skill" = no ]; then
    fail "$folder" "has integration.json but no SKILL.md"
    continue
  fi
  if [ "$has_manifest" = no ]; then
    fail "$folder" "has SKILL.md but no integration.json"
    continue
  fi

  folder_ok=yes
  if ! [[ "$folder" =~ ^[a-z][a-z0-9-]*$ ]]; then
    fail "$folder" "the folder name is not a valid integration ID (^[a-z][a-z0-9-]*\$)"
    folder_ok=no
  fi

  if ! jq -e . "$dir/integration.json" >/dev/null 2>&1; then
    fail "$folder" "integration.json is not valid JSON"
    continue
  fi
  problems="$(manifest_problems "$dir/integration.json")"
  if [ -n "$problems" ]; then
    while IFS= read -r problem; do
      fail "$folder" "integration.json: $problem"
    done <<EOF
$problems
EOF
    folder_ok=no
  fi

  skill_name="$(awk '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    /^name:/ { sub(/^name:[[:space:]]*/, ""); gsub(/["'\'']/, ""); print; exit }
  ' "$dir/SKILL.md")"
  if [ -z "$skill_name" ]; then
    fail "$folder" "SKILL.md has no name in its front matter"
    folder_ok=no
  fi

  if [ "$folder_ok" = yes ]; then
    echo "ok   $folder (skill: $skill_name)"
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "$failures problem(s) in $integrations integration folder(s)"
  exit 1
fi
echo "all $integrations integration folder(s) pass"

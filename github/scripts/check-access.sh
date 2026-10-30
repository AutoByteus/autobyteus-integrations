#!/usr/bin/env bash
# Checks this run's GitHub access through AutoByteus.
# Usage: check-access.sh
set -euo pipefail
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

GH_USAGE="usage: check-access.sh"
[ "$#" -eq 0 ] || gh_usage_error "check-access.sh takes no arguments"

gh_require_tools curl jq
gh_require_access

user="$(gh_request GET /user)" || exit $?
login="$(printf '%s' "$user" | jq -r '.login')"
echo "GitHub access: connected as @$login"

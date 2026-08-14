#!/usr/bin/env bash
set -euo pipefail
HARNESS_CONFIG_FILE="${HARNESS_CONFIG_FILE:-harness.config.yaml}"

_harness_cfg_get() {
  local key="$1" file="$2"
  [[ -f "$file" ]] || return 1
  local line
  line="$(grep -E "^[[:space:]]${key}:" "$file" | head -1)" || return 1
  line="${line#*:}"
  line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')"
  [[ -n "$line" ]] || return 1
  printf '%s' "$line"
}

harness_load_config() {
  local root="${1:-.}"
  local cfg="$root/$HARNESS_CONFIG_FILE"
  PROJECT_NAME="${PROJECT_NAME:-$(_harness_cfg_get name "$cfg" 2>/dev/null || echo __PROJECT_NAME__)}"
  PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-$(_harness_cfg_get description "$cfg" 2>/dev/null || echo __PROJECT_DESCRIPTION__)}"
  VERIFY_INSTALL="${VERIFY_INSTALL:-$(_harness_cfg_get install "$cfg" 2>/dev/null || echo "npm ci")}"
  VERIFY_TEST="${VERIFY_TEST:-$(_harness_cfg_get test "$cfg" 2>/dev/null || echo "npm test")}"
  VERIFY_BUILD="${VERIFY_BUILD:-$(_harness_cfg_get build "$cfg" 2>/dev/null || echo "npm run build")}"
  export PROJECT_NAME PROJECT_DESCRIPTION VERIFY_INSTALL VERIFY_TEST VERIFY_BUILD
}

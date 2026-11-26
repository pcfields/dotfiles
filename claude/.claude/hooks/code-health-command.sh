# shellcheck shell=bash disable=SC2034  # cmd is read by the sourcing hook
# Sourced by the code-health hooks. Sets `cmd` to the code-health command:
# CODE_HEALTH_CMD if set, else code-health on PATH. Returns 1 when neither is
# available.
code_health_command() {
  if [[ -n "${CODE_HEALTH_CMD:-}" ]]; then
    read -ra cmd <<<"$CODE_HEALTH_CMD"
  elif command -v code-health >/dev/null; then
    cmd=(code-health)
  else
    return 1
  fi
}

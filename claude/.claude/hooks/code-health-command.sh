# shellcheck shell=bash disable=SC2034  # cmd is read by the sourcing hook
# Sourced by the code-health hooks. Sets `cmd` to the code-health command:
# CODE_HEALTH_CMD if set, else code-health on PATH, else `uv run` on the
# stowed tool (until `uv tool install` puts it on PATH, plan step 11).
# Returns 1 when none is available.
code_health_command() {
  local tool="$HOME/.agents/tools/code-health"
  if [[ -n "${CODE_HEALTH_CMD:-}" ]]; then
    read -ra cmd <<<"$CODE_HEALTH_CMD"
  elif command -v code-health >/dev/null; then
    cmd=(code-health)
  elif command -v uv >/dev/null && [[ -d "$tool" ]]; then
    cmd=(uv run --quiet --locked --project "$tool" code-health)
  else
    return 1
  fi
}

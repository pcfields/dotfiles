#!/usr/bin/env bash
# Prints what the repo-health skill needs: which source files change most, how
# complex they are, which ones change together and how many authors touch them.
# Complexity is measured from indentation, so it works for any language. When
# lizard is installed, functions that are long, branchy or take many
# parameters are listed too and count towards the file's grade.
# Run inside a git repo: bash repo-health.sh [--since <date>] [--top <n>] [<path>]
set -euo pipefail

# Lockfiles, data, dumps and prose: they churn, but indentation says nothing about them.
SKIP_FILES='(^|/)(flake\.lock|yarn\.lock|pnpm-lock\.yaml)$|\.(lock|json|md|txt|csv|svg|snap|map|log|dump|bak)$|\.min\.(js|css)$'
# Commits touching more files than this are bulk edits, not evidence of coupling.
MAX_COMMIT_FILES=50
# Pairs that changed together fewer times than this are noise.
MIN_SHARED_COMMITS=3
# A function at or past any FLAG_ value is flagged (yellow); past a RED_ value
# it is red. Rough and uncalibrated, like the file thresholds in grades().
FLAG_CCN=10 FLAG_LENGTH=60 FLAG_PARAMS=5
RED_CCN=20 RED_LENGTH=120

main() {
  local since="12 months ago" top=15 path="."
  while (($#)); do
    case "$1" in
      --since | --top)
        if (($# < 2)); then
          echo "$1 needs a value" >&2
          usage >&2
          exit 2
        fi
        if [[ "$1" == --since ]]; then since="$2"; else top="$2"; fi
        shift 2
        ;;
      -h | --help) usage; exit 0 ;;
      -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
      *) path="$1"; shift ;;
    esac
  done

  # git log prints paths from the repo root, so work from there.
  [[ "$path" == /* ]] || path="$(git rev-parse --show-prefix)$path"
  cd "$(git rev-parse --show-toplevel)"

  local work
  work="$(mktemp -d)"
  trap "rm -rf '$work'" EXIT
  touch "$work/churn" "$work/coupling" "$work/totals" "$work/functions"

  source_files "$path" >"$work/files"
  if [[ ! -s "$work/files" ]]; then
    echo "no source files under $path" >&2
    exit 1
  fi
  change_log "$since" "$path" | history_stats "$work/files" "$work"
  indentation <"$work/files" >"$work/indentation"
  # lizard is optional: without it, or if it fails, the rest still reports.
  local no_functions=""
  if ! command -v lizard >/dev/null; then
    no_functions="lizard not installed"
  elif ! function_metrics <"$work/files" >"$work/functions"; then
    no_functions="lizard failed"
    : >"$work/functions"
  fi
  grades "$work/functions" "$work/indentation" >"$work/complexity"
  hotspots "$work/complexity" "$work/churn" >"$work/hotspots"

  overview "$since" "$path" "$top" "$work"
  table "Hotspots (commits x complexity, worst first)" \
    "score	grade	commits	authors	lines	depth	complexity	file" \
    < <(head -n "$top" "$work/hotspots")
  table "Change coupling (files that change in the same commit)" \
    "shared	degree	file	changes with" \
    < <(sort -t$'\t' -k1,1nr -k2,2nr "$work/coupling" | head -n "$top")
  table "Author density (most authors first)" \
    "authors	commits	file" \
    < <(awk -F'\t' '$3 > 1 { print $3 "\t" $2 "\t" $1 }' "$work/churn" |
      sort -t$'\t' -k1,1nr -k2,2nr | head -n "$top")
  table "Least healthy files, changed or not" \
    "grade	lines	depth	complexity	file" \
    < <(awk -F'\t' '$5 != "green" { print $5 "\t" $2 "\t" $4 "\t" $3 "\t" $1 }' "$work/complexity" |
      sort -t$'\t' -k1,1 -k4,4nr | head -n "$top")
  if [[ -z "$no_functions" ]]; then
    table "Functions over the limits (ccn $FLAG_CCN+, $FLAG_LENGTH+ lines or $FLAG_PARAMS+ parameters)" \
      "ccn	lines	params	function	location" \
      < <(awk -F'\t' '$7 > 0 { print $7 "\t" $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 ":" $6 }' "$work/functions" |
        sort -t$'\t' -k1,1nr -k2,2nr -k3,3nr | cut -f2- | head -n "$top")
  else
    printf '\n## Functions over the limits\n'
    echo "($no_functions: function length, branching and parameters not measured)"
  fi
}

usage() {
  cat <<'EOF'
usage: repo-health.sh [--since <git date>] [--top <n>] [<path>]
  --since  how far back to read history (default: "12 months ago")
  --top    rows per table (default: 15)
  <path>   limit the report to a directory (default: whole repo)
EOF
}

# source_files <path>: non-binary, non-empty files worth measuring: tracked
# ones plus new ones not yet committed (ignored files stay out).
source_files() {
  git -c core.quotePath=false grep -Il --untracked '' -- "$1" | grep -Ev "$SKIP_FILES" || true
}

# change_log <since> <path>: one \001<author> line per commit, then its files.
change_log() {
  git -c core.quotePath=false log --since="$1" --no-merges \
    --format='%x01%an' --name-only -- "$2"
}

# history_stats <files> <outdir>: reads change_log on stdin and writes
#   churn:    file, commits, authors
#   coupling: shared commits, degree, file a, file b
#   totals:   commits, authors
history_stats() {
  awk -F'\t' -v max="$MAX_COMMIT_FILES" -v min="$MIN_SHARED_COMMITS" -v out="$2" '
    NR == FNR { tracked[$0] = 1; next }
    substr($0, 1, 1) == "\001" {
      end_commit()
      author = substr($0, 2)
      total++
      if (!(author in people)) { people[author] = 1; npeople++ }
      next
    }
    $0 in tracked { changed[++n] = $0 }
    END {
      end_commit()
      for (f in commits) print f "\t" commits[f] "\t" authors[f] > (out "/churn")
      for (p in shared) {
        if (shared[p] < min) continue
        split(p, pair, SUBSEP)
        # degree: shared commits as a share of the average commits of the two files
        degree = 200 * shared[p] / (commits[pair[1]] + commits[pair[2]])
        printf "%d\t%d%%\t%s\t%s\n", shared[p], degree, pair[1], pair[2] > (out "/coupling")
      }
      printf "%d\t%d\n", total, npeople > (out "/totals")
    }
    function end_commit(   i, j, f) {
      for (i = 1; i <= n; i++) {
        f = changed[i]
        commits[f]++
        if (!((f, author) in seen)) { seen[f, author] = 1; authors[f]++ }
      }
      if (n <= max)
        for (i = 1; i < n; i++)
          for (j = i + 1; j <= n; j++) shared[changed[i], changed[j]]++
      n = 0
    }
  ' "$1" -
}

# indentation: reads file names on stdin, prints
#   file, lines, complexity, depth
# lines counts non-blank lines; depth is the deepest indentation level;
# complexity is the sum over lines of (1 + indentation level).
indentation() {
  sed 's|^|./|' | tr '\n' '\0' | xargs -0 -r awk '
    FNR == 1 { if (file != "") report(); file = FILENAME; lines = 0; previous = 0; split("", steps) }
    /^[ \t]*$/ { next }
    {
      match($0, /^[ \t]*/)
      lead = substr($0, 1, RLENGTH)
      lines++
      tabs[lines] = gsub(/\t/, "", lead)
      spaces[lines] = length(lead)
      # count how often each indent step occurs; 1 is comment alignment, not a step
      step = spaces[lines] - previous
      if (step > 1) steps[step]++
      previous = spaces[lines]
    }
    END { if (file != "") report() }

    function report(   i, s, unit, level, above, total, deepest) {
      # the indent unit is the most common step between consecutive lines
      unit = 4
      if (!(unit in steps)) steps[unit] = 0
      for (s in steps) if (steps[s] > steps[unit] || (steps[s] == steps[unit] && s + 0 < unit)) unit = s + 0
      for (i = 1; i <= lines; i++) {
        level = tabs[i] + int(spaces[i] / unit)
        # a line aligned far to the right is still only one level deeper
        if (level > above + 1) level = above + 1
        above = level
        total += 1 + level
        if (level > deepest) deepest = level
      }
      printf "%s\t%d\t%d\t%d\n", substr(file, 3), lines, total, deepest
    }
  '
}

# function_metrics: reads file names on stdin and prints, for every function
# lizard can parse:
#   ccn, length, params, name, file, start line, level (0 ok, 1 flagged, 2 red)
function_metrics() {
  sed 's|^|./|' | tr '\n' '\0' | xargs -0 -r lizard --csv -i -1 |
    awk -v fc="$FLAG_CCN" -v fl="$FLAG_LENGTH" -v fp="$FLAG_PARAMS" \
      -v rc="$RED_CCN" -v rl="$RED_LENGTH" '
      {
        # nloc,ccn,tokens,params,length,"location","file","name","long name",start,end
        n = split($0, quoted, "\",\"")
        if (n < 4) next
        split(quoted[1], head, ",")
        m = split(quoted[n], tail, ",")
        ccn = head[2]; params = head[4]; length_ = head[5]
        level = 0
        if (ccn >= fc || length_ >= fl || params >= fp) level = 1
        if (ccn >= rc || length_ >= rl) level = 2
        printf "%d\t%d\t%d\t%s\t%s\t%d\t%d\n",
          ccn, length_, params, quoted[3], substr(quoted[2], 3), tail[m - 1], level
      }
    '
}

# grades <functions> <indentation>: prints each indentation row with a grade:
#   file, lines, complexity, depth, grade
# The grade is the worse of the file's own (length, nesting depth) and its
# worst function's level. The thresholds are rough and uncalibrated.
grades() {
  awk -F'\t' '
    BEGIN { name[0] = "green"; name[1] = "yellow"; name[2] = "red" }
    FILENAME == ARGV[1] { if ($7 > worst[$5]) worst[$5] = $7; next }
    {
      level = 0
      if ($2 >= 400 || $4 >= 6) level = 1
      if ($2 >= 1000 || $4 >= 8) level = 2
      if (worst[$1] > level) level = worst[$1]
      print $0 "\t" name[level]
    }
  ' "$1" "$2"
}

# hotspots <complexity> <churn>: files changed in the window, worst first:
#   score, grade, commits, authors, lines, depth, complexity, file
hotspots() {
  awk -F'\t' '
    NR == FNR { lines[$1] = $2; weight[$1] = $3; depth[$1] = $4; grade[$1] = $5; next }
    $1 in weight {
      printf "%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\n",
        $2 * weight[$1], grade[$1], $2, $3, lines[$1], depth[$1], weight[$1], $1
    }
  ' "$1" "$2" | sort -t$'\t' -k1,1nr
}

# overview <since> <path> <top> <workdir>
overview() {
  local since="$1" path="$2" top="$3" work="$4"
  printf '## Overview\n'
  printf 'repo: %s   path: %s   window: since %s\n' "$(basename "$PWD")" "$path" "$since"
  awk -F'\t' '{ printf "commits: %d   authors: %d\n", $1, $2 }' "$work/totals"
  printf 'source files: %d   changed in window: %d\n' \
    "$(wc -l <"$work/files")" "$(wc -l <"$work/churn")"
  awk -F'\t' '{ count[$5]++ } END {
    printf "grades: %d green, %d yellow, %d red\n", count["green"], count["yellow"], count["red"]
  }' "$work/complexity"
  awk -F'\t' -v top="$top" '
    { all += $3 } NR <= top { hot += $3 }
    END { if (all) printf "top %d hotspots take %d%% of all file changes\n", top, 100 * hot / all }
  ' "$work/hotspots"
}

# table <title> <header>: prints the rows on stdin as aligned columns, or "(none)".
table() {
  local title="$1" header="$2" rows
  rows="$(cat)"
  printf '\n## %s\n' "$title"
  if [[ -z "$rows" ]]; then
    echo "(none)"
  else
    printf '%s\n%s\n' "$header" "$rows" | column -t -s $'\t'
  fi
}

main "$@"

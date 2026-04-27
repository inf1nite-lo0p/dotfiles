#!/usr/bin/env bash
# shadcn-flavored Claude Code status line — v3 (dot-segment design)
# Layout:
#   <model>  |  ctx X%  |  $X.XX  |  <dir> (<branch>)
#   current  ● ● ● ● ● ○ ○ ○ ○ ○ ○   X%  ↻ Xhr Ymin
#   weekly   ● ● ● ● ● ● ○ ○ ○ ○ ○   X%  ↻ Sat 6:00am
# Branch is an OSC 8 hyperlink to the GitHub branch when remote is GitHub.

set -uo pipefail

input=$(cat)

# Palette
BRIGHT=$'\033[38;5;255m'   # zinc-50   — model
PRIMARY=$'\033[38;5;251m'  # zinc-300  — dir, filled dots
MUTED=$'\033[38;5;244m'    # zinc-500  — labels, branch, mid-range %
DIM=$'\033[38;5;240m'      # zinc-600  — empty dots, ↻, reset times
SUBTLE=$'\033[38;5;238m'   # zinc-700  — | separators
SAFE=$'\033[38;5;78m'      # green-400 — % when <10
WARN=$'\033[38;5;179m'     # amber-400 — % when 75–89
DANGER=$'\033[38;5;210m'   # rose-400  — % when ≥90
RESET=$'\033[0m'

j() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

model=$(j '.model.display_name // "Claude"')
cwd=$(j '.workspace.current_dir // .cwd // "."')
dir=$(basename "$cwd")
ctx_pct=$(j '.context_window.used_percentage // 0' | cut -d. -f1)
cost=$(j '.cost.total_cost_usd // 0')
rl_5h_pct=$(j '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
rl_5h_reset=$(j '.rate_limits.five_hour.resets_at // empty')
rl_7d_pct=$(j '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
rl_7d_reset=$(j '.rate_limits.seven_day.resets_at // empty')

branch=""
branch_link=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  branch_disp="$branch"
  [ ${#branch_disp} -gt 28 ] && branch_disp="${branch_disp:0:27}…"
  remote=$(git -C "$cwd" remote get-url origin 2>/dev/null)
  if [ -n "$remote" ]; then
    url=$(printf '%s' "$remote" | sed -E 's#^git@([^:]+):#https://\1/#; s#\.git$##')
    if [[ "$url" == https://github.com/* && -n "$branch" ]]; then
      branch_link=$(printf '\033]8;;%s/tree/%s\007%s\033]8;;\007' "$url" "$branch" "$branch_disp")
    fi
  fi
  [ -z "$branch_link" ] && branch_link="$branch_disp"
fi

pct_color() {
  local p=$1
  if   [ "$p" -lt 10 ]; then printf '%s' "$SAFE"
  elif [ "$p" -ge 90 ]; then printf '%s' "$DANGER"
  elif [ "$p" -ge 75 ]; then printf '%s' "$WARN"
  else                       printf '%s' "$MUTED"
  fi
}

make_dots() {
  local pct=$1 width=11 filled i out=""
  filled=$((pct * width / 100))
  [ $filled -gt $width ] && filled=$width
  for ((i=0; i<width; i++)); do
    if [ $i -lt $filled ]; then
      out+="${PRIMARY}●${RESET}"
    else
      out+="${DIM}○${RESET}"
    fi
    [ $((i+1)) -lt $width ] && out+=" "
  done
  printf '%s' "$out"
}

fmt_5h_reset() {
  local epoch=$1 now diff hr mn
  now=$(date +%s)
  diff=$((epoch - now))
  [ $diff -le 0 ] && { printf 'now'; return; }
  hr=$((diff / 3600))
  mn=$(((diff % 3600) / 60))
  if [ $hr -gt 0 ]; then
    printf '%dhr %dmin' "$hr" "$mn"
  else
    printf '%dmin' "$mn"
  fi
}

fmt_7d_reset() {
  local s
  s=$(date -r "$1" '+%a %-l:%M%p' 2>/dev/null || date -d "@$1" '+%a %-l:%M%p')
  s="${s/AM/am}"
  s="${s/PM/pm}"
  printf '%s' "$s"
}

fmt_7d_remaining() {
  local epoch=$1 now diff dy hr mn
  now=$(date +%s)
  diff=$((epoch - now))
  [ $diff -le 0 ] && { printf 'now'; return; }
  dy=$((diff / 86400))
  hr=$(((diff % 86400) / 3600))
  mn=$(((diff % 3600) / 60))
  if [ $dy -gt 0 ]; then
    printf '%dd %dhr left' "$dy" "$hr"
  elif [ $hr -gt 0 ]; then
    printf '%dhr %dmin left' "$hr" "$mn"
  else
    printf '%dmin left' "$mn"
  fi
}

sep="${SUBTLE}|${RESET}"

# Line 1
ctx_color=$(pct_color "$ctx_pct")
cost_str=$(printf '$%.2f' "$cost")
line1="${BRIGHT}${model}${RESET}  ${sep}  ${MUTED}ctx${RESET} ${ctx_color}${ctx_pct}%${RESET}  ${sep}  ${MUTED}${cost_str}${RESET}  ${sep}  ${PRIMARY}${dir}${RESET}"
[ -n "$branch" ] && line1="${line1} ${MUTED}(${branch_link})${RESET}"

# Line 2 — current (5h)
line2=""
if [ -n "${rl_5h_pct:-}" ]; then
  c=$(pct_color "$rl_5h_pct")
  dots=$(make_dots "$rl_5h_pct")
  pad=$(printf '%3s' "${rl_5h_pct}%")
  reset_str=""
  [ -n "${rl_5h_reset:-}" ] && reset_str="  ${DIM}↻ $(fmt_5h_reset "$rl_5h_reset")${RESET}"
  line2="${MUTED}$(printf '%-7s' current)${RESET}  ${dots}  ${c}${pad}${RESET}${reset_str}"
fi

# Line 3 — weekly (7d)
line3=""
if [ -n "${rl_7d_pct:-}" ]; then
  c=$(pct_color "$rl_7d_pct")
  dots=$(make_dots "$rl_7d_pct")
  pad=$(printf '%3s' "${rl_7d_pct}%")
  reset_str=""
  [ -n "${rl_7d_reset:-}" ] && reset_str="  ${DIM}↻ $(fmt_7d_reset "$rl_7d_reset") ($(fmt_7d_remaining "$rl_7d_reset"))${RESET}"
  line3="${MUTED}$(printf '%-7s' weekly)${RESET}  ${dots}  ${c}${pad}${RESET}${reset_str}"
fi

printf '%b\n' "$line1"
[ -n "$line2" ] && printf '%b\n' "$line2"
[ -n "$line3" ] && printf '%b\n' "$line3"
exit 0

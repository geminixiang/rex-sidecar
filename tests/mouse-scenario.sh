#!/bin/bash
set -u

T=com.superlogical.terminal
CONFIG=${REX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/rex/init.lua}
SESSION=${REX_SESSION:?run inside a Rex terminal}
FAIL=0

FIX=$(mktemp -d /tmp/rsc.XXXX)/project
mkdir -p "$FIX/src/lib" "$FIX/docs"
printf '# Project\n' > "$FIX/README.md"
printf 'export const a = 1;\n' > "$FIX/src/main.ts"
printf 'export const b = 2;\n' > "$FIX/src/lib/util.ts"
printf '# Guide\n' > "$FIX/docs/guide.md"
seq 1 200 > "$FIX/long.txt"
git -C "$FIX" init -q && git -C "$FIX" add . && git -C "$FIX" -c user.email=t@t -c user.name=t commit -qm init
printf 'new\n' > "$FIX/untracked.txt"

mouse() { rex do -e "local e=string.char(27) rex.block.call('$T','write',{block_id='$1',data=e..'[<$2;$3;${4}M'..e..'[<$2;$3;${4}m'}) return 1" >/dev/null; }
click() { mouse "$1" 0 "$2" "$3"; }
wheel_down() { mouse "$1" 65 "$2" "$3"; }
row_of() { rex capture -b "$1" | sed '1d' | grep -n -E -- "[[:space:]]$2([[:space:]]|$)" | head -1 | awk -F: '{print $1 + 1}'; }
header() { rex capture -b "$Y" | head -1 | sed 's/ *$//'; }
viewer_id() { rex block list --json | jq -r --arg w "$W" '.blocks[] | select(.window_id == $w and .label == "viewer") | .block_id'; }
viewer_file() { rex capture -b "$V" --trim | grep -E '\[RO\]' | tail -1 | awk '{print $1}'; }
focused() { rex do -e 'return rex.session.view{}' --json | jq -r --arg w "$W" '.. | objects | select(.window_id? == $w) | .focused_block_id? // empty' | head -1; }
wait_for() { local i; for i in $(seq 30); do eval "$1" && return 0; sleep 0.1; done; return 1; }
ms() { echo $(( ($(date +%s%N) - $1) / 1000000 )); }
step() { printf '\n▶ %s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }
bad() { printf '  ✗ %s\n' "$*"; FAIL=1; }

out=$(rex window new -s "$SESSION" rex-sidecar-test -c "$FIX" --focus=false --json)
M=$(echo "$out" | jq -r '.block_ids[0]')
W=$(echo "$out" | jq -r .window_id)
cleanup() { [ -n "${KEEP:-}" ] && return; rex window close "$W" >/dev/null 2>&1; rm -rf "$(dirname "$FIX")"; }
trap cleanup EXIT
sleep 1

step "open the sidecar (Cmd+Shift+E)"
Y=$(rex do "$CONFIG" --action sidecar_open -b "$M" --json | jq -r '.block_ids[0]')
wait_for '[[ "$(header)" == *project ]]' && ok "$(header)" || bad "sidecar did not open"

step "git status marker on untracked file"
wait_for 'rex capture -b "$Y" | grep -q "untracked.txt.*?"' && ok "untracked.txt shows ?" || bad "no git marker"

step "click folder src"
click "$Y" 5 "$(row_of "$Y" 'src')"
wait_for '[[ "$(header)" == */src ]]' && ok "$(header)" || bad "did not enter src: $(header)"

step "click nested folder lib, then a file in it"
click "$Y" 5 "$(row_of "$Y" 'lib')"
wait_for '[[ "$(header)" == */src/lib ]]' && ok "$(header)" || bad "did not enter lib"
t0=$(date +%s%N)
click "$Y" 5 "$(row_of "$Y" 'util\.ts')"
wait_for 'V=$(viewer_id); [ -n "$V" ] && [[ "$(viewer_file)" == *util.ts ]]' && ok "preview util.ts in $(ms "$t0")ms" || bad "viewer did not show util.ts"
[ "$(focused)" = "$Y" ] && ok "focus stays in sidebar" || bad "focus moved to $(focused)"

step "click header ‹ twice to go back to the project root"
click "$Y" 2 1
wait_for '[[ "$(header)" == */src ]]' && ok "$(header)" || bad "did not go up: $(header)"
click "$Y" 2 1
wait_for '[[ "$(header)" == *project ]]' && ok "$(header)" || bad "did not go up: $(header)"

step "click another file: same viewer updates"
t0=$(date +%s%N)
click "$Y" 5 "$(row_of "$Y" 'long\.txt')"
wait_for '[[ "$(viewer_file)" == *long.txt ]]' && ok "updated in $(ms "$t0")ms" || bad "viewer shows $(viewer_file)"
n=$(viewer_id | wc -l | tr -d ' ')
[ "$n" = 1 ] && ok "exactly one viewer" || bad "$n viewers"

step "wheel in the sidebar"
before=$(rex capture -b "$Y" | tail -1 | grep -oE '[0-9]+/[0-9]+')
for _ in 1 2 3; do wheel_down "$Y" 5 4; done
sleep 0.5
after=$(rex capture -b "$Y" | tail -1 | grep -oE '[0-9]+/[0-9]+')
[ "$before" != "$after" ] && ok "cursor $before → $after" || bad "wheel ignored ($before)"

step "wheel in the viewer"
V=$(viewer_id)
click "$Y" 5 "$(row_of "$Y" 'long\.txt')"
wait_for '[[ "$(viewer_file)" == *long.txt ]]'
top_before=$(rex capture -b "$V" | head -1 | awk '{print $1}')
for _ in 1 2 3; do wheel_down "$V" 20 10; done
sleep 0.5
top_after=$(rex capture -b "$V" | head -1 | awk '{print $1}')
[ "$top_before" != "$top_after" ] && ok "first line $top_before → $top_after" || bad "viewer wheel ignored"

step "right-click a file focuses the viewer"
click_right() { mouse "$1" 2 "$2" "$3"; }
click_right "$Y" 5 "$(row_of "$Y" 'README\.md')"
wait_for '[ "$(focused)" = "$V" ]' && ok "viewer focused, showing $(viewer_file)" || bad "focus is $(focused)"

echo
[ $FAIL = 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }

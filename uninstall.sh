#!/bin/sh
set -eu

config=${REX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/rex/init.lua}
target=$(dirname "$config")/rex-sidecar

if [ -f "$config" ]; then
  tmp=$(mktemp)
  grep -vF 'require("rex-sidecar")' "$config" > "$tmp" || true
  cat "$tmp" > "$config"
  rm -f "$tmp"
fi

if [ -L "$target" ]; then
  rm "$target"
elif [ -d "$target" ]; then
  rm -rf "$target"
fi
rm -rf /tmp/rex-sidecar-"$(id -u)"-*

if [ -z "${REX_SIDECAR_NO_RELOAD:-}" ]; then
  rex config reload >/dev/null
fi
echo "rex-sidecar removed."

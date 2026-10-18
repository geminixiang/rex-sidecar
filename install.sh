#!/bin/sh
set -eu

repo=$(cd "$(dirname "$0")" && pwd)
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/rex
config=${REX_CONFIG:-$config_dir/init.lua}
link=$(dirname "$config")/rex-sidecar
line='require("rex-sidecar").setup{}'

missing=""
for cmd in rex yazi ya nvim jq; do
  command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
done
if [ -n "$missing" ]; then
  echo "missing:$missing" >&2
  echo "install with: brew install yazi neovim jq" >&2
  exit 1
fi

mkdir -p "$(dirname "$config")"
if [ "$repo" != "$link" ]; then
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "$link exists and is not a symlink; move it away first" >&2
    exit 1
  fi
  ln -sfn "$repo" "$link"
fi

if [ ! -d "$repo/yazi/plugins/git.yazi" ]; then
  YAZI_CONFIG_HOME="$repo/yazi" ya pkg install >/dev/null
fi

touch "$config"
grep -qF 'require("rex-sidecar")' "$config" || printf '\n%s\n' "$line" >> "$config"

rex config reload >/dev/null
rex config check
echo "rex-sidecar installed. Press Cmd+Shift+E in a Rex terminal."

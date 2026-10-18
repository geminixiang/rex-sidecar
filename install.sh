#!/bin/sh
set -eu

REPO_URL=${REX_SIDECAR_REPO:-https://github.com/geminixiang/rex-sidecar.git}
config=${REX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/rex/init.lua}
config_dir=$(dirname "$config")
target=$config_dir/rex-sidecar
line='require("rex-sidecar").setup{}'

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v rex >/dev/null 2>&1 || die "rex not found. Install Rex first: https://www.superlogical.com/rex"
command -v git >/dev/null 2>&1 || die "git not found"

missing=""
for pair in yazi:yazi ya:yazi nvim:neovim jq:jq; do
  cmd=${pair%%:*}
  pkg=${pair#*:}
  command -v "$cmd" >/dev/null 2>&1 || case " $missing " in *" $pkg "*) ;; *) missing="$missing $pkg" ;; esac
done
if [ -n "$missing" ]; then
  command -v brew >/dev/null 2>&1 || die "missing:$missing. Install them and run this again."
  say "Installing$missing with Homebrew"
  brew install $missing
fi

self_dir=""
case "$0" in */install.sh) self_dir=$(cd "$(dirname "$0")" && pwd) ;; esac

mkdir -p "$config_dir"
if [ -n "$self_dir" ] && [ -f "$self_dir/init.lua" ] && [ -d "$self_dir/yazi" ]; then
  if [ "$self_dir" != "$target" ]; then
    if [ -e "$target" ] && [ ! -L "$target" ]; then die "$target exists and is not a symlink; move it away first"; fi
    say "Linking $target -> $self_dir"
    ln -sfn "$self_dir" "$target"
  fi
elif [ -d "$target/.git" ]; then
  say "Updating $target"
  git -C "$target" pull --ff-only --quiet
elif [ -e "$target" ]; then
  die "$target exists; remove it and run this again"
else
  say "Cloning into $target"
  git clone --quiet --depth 1 "$REPO_URL" "$target"
fi

say "Installing yazi plugins"
YAZI_CONFIG_HOME="$target/yazi" ya pkg install >/dev/null 2>&1

touch "$config"
if grep -qF 'require("rex-sidecar")' "$config"; then
  say "$config already loads rex-sidecar"
else
  say "Adding rex-sidecar to $config"
  printf '\n%s\n' "$line" >> "$config"
fi

if [ -z "${REX_SIDECAR_NO_RELOAD:-}" ]; then
  rex config reload >/dev/null && say "Reloaded Rex config"
fi

say "Done. Press Cmd+Shift+E in a Rex terminal."

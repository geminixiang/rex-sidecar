# rex-sidecar

A mouse-friendly file explorer and file viewer for the [Rex](https://www.superlogical.com/rex) terminal.

Press `Cmd+Shift+E` in any Rex terminal. A sidebar opens on the left, rooted at the
directory your terminal is in. Click a file and it appears in a viewer pane next to
the sidebar, while focus stays in the sidebar so you can keep browsing.

```
┌──────────┬───────────────────────────────┬────────────┐
│ ‹ ~/app  │  1 # README                   │ ❯ your     │
│   src    │  2                            │   shell    │
│   docs   │  3 ...                        │            │
│ ? new.ts │                               │            │
│   README │ README.md [RO]                │            │
└──────────┴───────────────────────────────┴────────────┘
  sidebar    viewer                          the terminal
  (yazi)     (nvim, read-only)               you were in
```

## Features

- **Opens where you are.** The sidebar starts in the working directory of the
  terminal you pressed the key in.
- **Live preview.** Moving the cursor or clicking a file shows it in the viewer.
  The viewer is reused, so there is only ever one.
- **Built for the mouse.**
  - Click a folder to enter it.
  - Click a file to preview it.
  - Right-click a file to focus the viewer.
  - Click the `‹ path` header, or press the mouse back button, to go up a level.
  - The scroll wheel works in both panes.
- **Git status.** Files and folders show `M`, `A`, `?`, `D` markers through
  [git.yazi](https://github.com/yazi-rs/plugins/tree/main/git.yazi).
- **Fast, quiet viewer.** The viewer runs `nvim --clean -R`, so your Neovim config
  and its plugins don't slow it down or print startup errors. It still has syntax
  highlighting, line numbers, and `/` search.
- **Leaves your setup alone.** It uses its own yazi config, so your normal
  `yazi` is unchanged.

The keyboard works too. In the sidebar, `j`/`k` move and preview, `l`/`h` go into
and out of folders, and `Enter` focuses the viewer.

## Requirements

- Rex (tested with server build `0.0.1792158932`)
- [yazi](https://yazi-rs.github.io) 26+
- [Neovim](https://neovim.io) 0.9+
- `jq`

```sh
brew install yazi neovim jq
```

## Install

```sh
git clone https://github.com/geminixiang/rex-sidecar ~/Github/rex-sidecar
~/Github/rex-sidecar/install.sh
```

`install.sh` does four things:

1. Symlinks the repo to `~/.config/rex/rex-sidecar`.
2. Installs the git.yazi plugin into the repo's private yazi config.
3. Adds `require("rex-sidecar").setup{}` to your `~/.config/rex/init.lua`.
4. Reloads the Rex config.

## Configure

Pass options to `setup` in your `~/.config/rex/init.lua`:

```lua
require("rex-sidecar").setup{
  key = "cmd+shift+e",
  sidebar_ratio = 0.2,
  viewer_ratio = 70,
}
```

| Option | Default | Meaning |
| --- | --- | --- |
| `key` | `"cmd+shift+e"` | Key that opens the sidebar. Set it to `false` and bind `sidecar_open` yourself. |
| `sidebar_ratio` | `0.2` | Share of the current pane that the sidebar takes. |
| `viewer_ratio` | `70` | Percent of the remaining pane that the viewer takes. |

The action is also in the command palette as **Sidecar: File Explorer**.

## How it works

- `init.lua` is a Rex config module. It finds the current terminal's directory
  with the terminal block's `pwd` and `process` methods. It then calls
  `rex.session.new_split` to start yazi beside that terminal.
- `yazi/` is a yazi config directory used only by the sidebar, through
  `YAZI_CONFIG_HOME`. A `hover` subscription previews files. Overrides of
  `Entity:click` and `Header:click` add the mouse behavior.
- `bin/rex-sidecar-open` makes sure the viewer pane exists with `rex split`. It
  then sends the file to that Neovim through its `--listen` socket. A lock stops
  fast cursor movement from opening two viewers.

## Test

The scenario test runs inside Rex. It builds a temporary git project, opens the
sidecar the way the key binding does, and then acts like a mouse user. It sends
real mouse clicks and wheel events to the panes, then checks what is on screen.

```sh
./tests/mouse-scenario.sh
```

The test can't click between panes, because Rex handles those clicks in the app
rather than in the terminal.

## Uninstall

1. Remove the `require("rex-sidecar")` line from `~/.config/rex/init.lua`.
2. Remove the symlink: `rm ~/.config/rex/rex-sidecar`.
3. Reload: `rex config reload`.

## License

MIT

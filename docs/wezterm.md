# WezTerm keybindings and UI

The config is `wezterm/.wezterm.lua`. This page is the quick reference; the
file is the source of truth.

## Leader

`SHIFT+Space`, active for 2 seconds. Everything below is `LEADER` followed by
the key. While the leader is active the workspace badge on the left turns gold
and the right status shows `LEADER`.

## Projects and tools

| Keys | Action |
|---|---|
| `LEADER SHIFT+F` | Find a project and open it in its own workspace |
| `LEADER g` | LazyGit in a new tab |
| `LEADER ;` | Claude in a new tab |
| `LEADER f` | Fuzzy workspace launcher |
| `LEADER .` / `LEADER ,` | Next / previous workspace |

## Panes

| Keys | Action |
|---|---|
| `LEADER s` then `h j k l` | Split left / down / up / right (stays active for 1s per key) |
| `LEADER r` then `h j k l` | Resize (same behavior) |
| `LEADER h j k l` | Move focus |
| `LEADER m` | Toggle zoom |
| `LEADER '` | Rotate panes clockwise |
| `LEADER v` | Pick a pane by label |
| `LEADER x` | Close pane (asks first) |

## Tabs

| Keys | Action |
|---|---|
| `LEADER t` | New tab |
| `LEADER SHIFT+X` | Close tab (asks first) |
| `LEADER o` / `LEADER i` | Next / previous tab |
| `LEADER a` | Alternate (last) tab |
| `LEADER 1` to `6` | Jump to tab by number |

## Copy and scrolling

| Keys | Action |
|---|---|
| `LEADER y` | Copy mode |
| `LEADER c` | Quick select |
| `LEADER u` / `LEADER d` | Page up / down |
| `LEADER ?` | Search scrollback |

## Mouse

Releasing a click only selects text. `CTRL+click` opens a link.

## Reading the bars

**Tabs** read `N: title`. `N` is the key after `LEADER`. A tool that titles
itself `<folder> - <tool>` (lazygit) shows just the tool, since the workspace
is already on the left. After the title, `ZOOM` means a pane in that tab is
zoomed and a row of `▪` marks a split tab, one per pane (`+` past four).

**Right status** only shows what is relevant, so it is empty when idle:

- the input mode: `LEADER`, or `SPLIT` / `RESIZE` / `COPY` / `SEARCH` while that
  key table is active
- `ZOOM` and `N panes` for the active tab
- `‹ previous ● next › (total)` for workspaces. The dot stands for the current
  workspace, so neither name reads as the active one. It is hidden with a
  single workspace.

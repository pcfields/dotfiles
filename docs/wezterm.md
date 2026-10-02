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
| `LEADER .` / `LEADER ,` | Next / previous workspace (alphabetical) |
| `LEADER w` | Back to the workspace you were in last; press again to toggle |

## Panes

| Keys | Action |
|---|---|
| `LEADER s` then `h j k l` | Split left / down / up / right (stays active for 1s per key) |
| `LEADER r` then `h j k l` | Resize (same behavior) |
| `LEADER h j k l` | Move focus |
| `LEADER z` | Toggle zoom |
| `LEADER '` | Rotate panes clockwise |
| `LEADER v` | Pick a pane by label |
| `LEADER x` | Close pane (asks first) |

## Tabs

| Keys | Action |
|---|---|
| `LEADER t` | New tab |
| `LEADER SHIFT+X` | Close tab (asks first) |
| `LEADER o` | Next tab |
| `LEADER i` | Previous tab |
| `LEADER SHIFT+o` | Move the tab right |
| `LEADER SHIFT+i` | Move the tab left |
| `LEADER a` | Alternate (last) tab |
| `LEADER 1` to `6` | Jump to tab by number |

## Copy and scrolling

| Keys | Action |
|---|---|
| `LEADER y` | Copy mode |
| `LEADER c` | Quick select |
| `LEADER u` / `LEADER d` | Page up / down |
| `LEADER ?` | Search scrollback |

Selected text is a solid iris block with dark text.

### Inside copy mode

`LEADER y` enters it (the right status shows `COPY`). Move, select, then yank.

| Keys | Action |
|---|---|
| `h j k l`, arrows | Move |
| `w` / `b` / `e` | Next word / previous word / end of word |
| `0` / `^` / `$` | Line start / first non-blank / line end |
| `g` / `G` | Top / bottom of the scrollback |
| `H` / `M` / `L` | Top / middle / bottom of the screen |
| `Ctrl-u` / `Ctrl-d` | Half a page up / down |
| `Ctrl-b` / `Ctrl-f` | A page up / down |
| `f` / `t` + char | Jump to / just before a character (`F` / `T` backward) |
| `;` / `,` | Repeat the last jump / reverse it |
| `v` / `V` / `Ctrl-v` | Select by character / line / block |
| `o` | Jump to the other end of the selection |
| `y` | Copy, clear the selection and leave copy mode |
| `Escape`, `q`, `Ctrl-c` | Leave without copying |

`y` is overridden (`keymap_builders.copy_mode_keys`): the built-in one copies
but leaves the text highlighted. Every other key is the default. There is no
`/` search inside copy mode; use `LEADER ?` instead.

## Mouse

Releasing a click only selects text and copies it. `CTRL+click` opens a link.

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
  single workspace. Names longer than 20 columns keep their end behind a
  leading `…`, because the names share a prefix (`…platform.landingpage`).
  The previous and next are alphabetical, as `LEADER .` and `,` cycle.

## Free LEADER keys

Computed from `wezterm show-keys` for the current config. Re-check after adding
bindings, since this list goes stale.

| Kind | Free |
|---|---|
| Letters | `b` `e` `m` `n` `p` `q` |
| Digits | `0` `7` `8` `9` (`1` to `6` jump to tabs) |
| Punctuation | `-` `=` `[` `]` `\` `` ` `` `/` |
| `LEADER SHIFT` + letter | everything except `F`, `X`, `O` and `I` |

Also unbound: `Space`, `Tab`, `Enter`, the arrow keys, and the function keys.
Taken punctuation is `'` `,` `.` `;` `?`.

Ideas that fit the existing mnemonics: `n` / `p` (next / previous) for
workspaces or tabs, `7` to `9` to extend the tab jumps, and `/` for a second
search entry point.

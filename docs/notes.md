# Notes / knowledge base

A vault of plain markdown articles, written in Neovim and read on GitHub (including
from the phone). Plugins live in `nvim/.config/nvim/lua/pcf/plugins/notes/`;
keymaps are under `<leader>n` in `config/keymaps.lua`.

obsidian.nvim is used as a note-taking engine only. The Obsidian app is not
involved, so there is no `.obsidian/` folder to maintain.

## Vault

- Location: `~/notes/Personal`. Override with the `NOTES_VAULT` environment
  variable, e.g. on Windows.
- The vault is **not** part of this repo. It is its own **private** GitHub repo,
  so articles are not mixed with config.

### First-time repo setup

```fish
cd ~/notes/Personal
git init -b main
printf '.DS_Store\n' > .gitignore
git add -A && git commit -m "chore: initial vault"
git remote add origin git@github.com:pcfields/personal-notebook.git
git push -u origin main
```

Check on GitHub that `personal-notebook` is **private** before pushing.

### Reading on the phone

Open the repo in the GitHub mobile app or in a browser. Markdown renders, and
links between notes are tappable because they are standard relative markdown
links.

## Conventions

- Filenames are lowercase with hyphens: a note titled "My Article" is saved as
  `my-article.md`.
- Links are markdown links, `[My Article](my-article.md)`. Wikilinks
  (`[[...]]`) are avoided because GitHub shows them as plain text.
- `templates/` holds templates, `attachments/` holds pasted images.
- No daily notes. Grow the base with links, and keep a few index notes
  ("maps of content") that link to related articles.

## Keymaps

| Key | Action |
|---|---|
| `<leader>nn` | New note |
| `<leader>nt` / `<leader>nT` | New note from template / insert template |
| `<leader>nf` | Find note by title |
| `<leader>ns` | Search note contents |
| `<leader>nb` / `<leader>nl` | Backlinks / links in this note |
| `<leader>ng` | Browse tags |
| `<leader>nr` | Rename note and update links |
| `<leader>np` | Paste image from clipboard |
| `<leader>nk` (visual) | Turn selection into a link |
| `<leader>nx` (visual) | Extract selection into a new note |
| `<CR>` on a link / checkbox / tag | Follow link, toggle checkbox, or browse tag |
| `gf` on a link | Follow link |

## First-time setup

1. `./install.sh stow`, then open Neovim and run `:Lazy sync`.
2. Check with `:checkhealth obsidian`.

## Templates

Templates live in the vault's `templates/` folder (they are vault content, not
part of this repo). Use `<leader>nt` to start a note from one.

| Template | Use for |
|---|---|
| `article.md` | A long-form article: summary, context, main points, open questions |
| `note.md` | One atomic idea in your own words, with a source |
| `index.md` | A curated list of links on one topic |

Only `{{title}}` and `{{date}}` are used. Any other `{{variable}}` makes the
plugin prompt for a value.

## Workflow

Pull before you start writing, commit and push when you finish:

```fish
cd ~/notes/Personal
git pull
# ...write...
git add -A && git commit -m "docs: add my-article" && git push
```

## Notes on LSP overlap

obsidian.nvim runs its own in-process LSP for link and tag completion, and
marksman is also configured for markdown. If you see duplicate completions or
links, disable marksman for the vault.

# Agent Instructions for Neovim Config

## Testing
- Validate the Neovim config: `nvim --headless -u NONE -l nvim/.config/nvim/tests/smoke.lua` from the repository root
- Run nearest test: `<leader>tt` via neotest
- Run current file tests: `<leader>tf` via neotest  
- Watch file: `<leader>tw` via neotest
- Test runner: neotest with vitest adapter

## Debugging
- Install missing debug adapters explicitly with `:DapInstallAdapters`

## Tree-sitter
- Install missing configured parsers explicitly with `:TSInstallConfigured`

## Formatting & Linting
- Auto-format on save via conform.nvim
- JS/TS: biome (preferred), prettier fallback
- Lua: stylua
- Linters: biomejs, eslint_d for JS/TS

## Code Style
- **Indentation**: Tabs (width 4) for Lua, 2 spaces for JS/TS/JSON
- **Line width**: 160 chars (Lua)
- **Quotes**: Prefer double quotes
- **Imports**: Use pcall for requiring modules (e.g., `local ok, mod = pcall(require, "module")`)
- **Naming**: Snake case for Lua vars/functions, return modules as `M`
- **Error handling**: Always use pcall for requires, early returns on failure
- **Comments**: Minimal, only for complex logic or configuration URLs
- **Plugin structure**: Return lazy.nvim spec tables, use `event` for lazy loading
- **Keymaps**: Use `require("pcf.utils").map()` helper, include `desc` for which-key

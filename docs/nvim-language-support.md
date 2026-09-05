# Neovim language support: Rust, F#, C#, and Node/TS debugging

> **Purpose.** Staged plan to add Rust, F#, and C# development to the Neovim config,
> and to repair Node/TypeScript debugging (which is currently non-functional).
>
> **Audience.** Written for two readers: the human following the stages by hand
> (Parts 1–3), and an AI agent picking the work up mid-flight (Part 4).
>
> **Created.** 2026-09-05. **Baseline commit:** `c601cf3`.
> **Status:** Stage 1 complete, plus the treesitter repair it uncovered.
> Stages 2-6 outstanding.

---

## Progress checklist

Update this as you go. An agent resuming work reads this first.

- [x] **Stage 1** — Repair Node/TypeScript debugging *(done)*
- [x] **Stage 2** — Rust *(done)*
- [ ] **Stage 3** — .NET foundation (shared by C# and F#)
- [ ] **Stage 4** — C#
- [ ] **Stage 5** — F#
- [ ] **Stage 6** — Cross-cutting polish and repo/doc updates
- [x] **Interlude** — developer environment breadth *(done; see below)*
- [x] **Interlude** — treesitter ported to the `main` branch *(done, `26277c0`)*

Stages 2–5 are independent of one another; only Stage 1 and Stage 3 are
prerequisites (Stage 3 blocks Stages 4 and 5). Stage 1 is first because it is a
repair of something you use daily, and because every later DAP stage copies its
pattern.

---

## Part 1 — Where things stand today (audit)

All statements below were verified on this machine on 2026-09-05, not inferred.

### Environment

| Thing | State |
|---|---|
| Neovim | 0.12.5 — native `vim.lsp.config()` / `vim.lsp.enable()` API, already used |
| Plugin manager | lazy.nvim, plugin-per-file under `lua/pcf/plugins/<category>/` |
| rustup / cargo / rustc | installed, `rustc 1.95.0` |
| `rust-analyzer` | **broken** — the binary on `PATH` is a rustup shim that errors: `Unknown binary 'rust-analyzer' in official toolchain`. The component is not installed. |
| `dotnet` | not installed |
| `lldb` / `gdb` / `codelldb` | none installed |
| Mason packages | was **empty**; `js-debug-adapter` installed during this audit |

### Rust

- `rust` treesitter parser is already in `ensure_installed`.
- No `rust_analyzer` entry in `lsp-config.lua`, and the binary would fail anyway (see above).
- No debug adapter, no `rustfmt` entry in conform (LSP fallback formatting would
  cover it once a server is running, but nothing is running).

### F# and C#

Nothing at all: no SDK, no LSP, no DAP, no treesitter parsers, no formatters.
Both parsers exist upstream and are installable (`c_sharp`, and `fsharp` from
`ionide/tree-sitter-fsharp` — confirmed present in the pinned nvim-treesitter).

### Node / TypeScript debugging — currently broken

Five distinct problems, in rough order of severity:

1. **The adapter was never installed.** `mason-nvim-dap` declares
   `ensure_installed = { "js-debug-adapter" }`, but it does not fire. Verified by
   a 90-second headless run: `mason-registry.get_installed_package_names()`
   returned `{}`. `:MasonInstall js-debug-adapter` by hand works fine. Net effect:
   `dap-vscode-js` registered the `pwa-node` / `pwa-chrome` / `pwa-msedge`
   adapters pointing at a `debugger_path` that did not exist, so every debug
   session failed at launch.

2. **`nvim-dap-vscode-js` is unmaintained.** Last commit `03bd296`, 2023-03-05.
   Modern configs define the `pwa-node` adapter directly against
   `js-debug-adapter`; the plugin is no longer needed.

3. **Configuration table aliasing bug** — `dap.lua`:

   ```lua
   dap.configurations.javascriptreact = dap.configurations.javascript
   dap.configurations.typescriptreact = dap.configurations.typescript
   ```

   These are table *references*, not copies. `add_browser_config()` then does
   `table.insert(dap.configurations.javascriptreact, ...)`, mutating the very
   same table `javascript` points at. Verified:

   ```
   js configs: 8   jsx: 8   same table: true
   js[1] Launch file      js[2] Attach
   js[3] Launch Edge for React   js[4] Launch Edge (port 3000)   js[5] Launch Edge (port 5173)
   js[6] Launch Chrome for React js[7] Launch Chrome (port 3000) js[8] Launch Chrome (port 5173)
   ```

   So starting a debug session in a plain backend `.ts` file offers six
   irrelevant browser launches. Fix is `vim.deepcopy`.

4. **No attach-to-port configuration.** There is no way to attach to
   `node --inspect`, `tsx watch`, `nodemon --inspect`, or a NestJS/Express dev
   server on `:9229`. For the backend work you described, this is the single most
   important missing piece — it is how you debug a running server rather than a
   one-shot script.

5. **No test-debugging configuration.** `<leader>td` maps to neotest's `dap`
   strategy, but there is no vitest/jest launch configuration behind it. Also,
   `neotest-jest` is listed as a dependency in `neo-test.lua` but never registered
   as an adapter, so only vitest projects are discovered.

Minor: `runtimeExecutable = "/usr/bin/microsoft-edge"` is hardcoded and
Linux-only; the config is stowed on Windows too, where it silently fails.

---

## Part 2 — Design decisions

Decisions made up front so the stages read as instructions rather than debates.
Each records the alternative in case you want to revisit.

### Where each tool comes from

The repo's boundary rules (`CLAUDE.md`, `AGENTS.md`) already answer most of this:
**LSP servers / formatters / linters → Nix**; **DAP adapters → Mason**;
**language runtimes → mise**. The plan follows them.

Mason's scope is exactly two packages. It is not that the adapters are hard to
install otherwise -- both are in nixpkgs -- but that neither is in scoop, and
`js-debug-adapter` is not on npm, so Windows has no other source. See
`docs/strategy.md` for the full reasoning.

| Tool | Role | Source | Why |
|---|---|---|---|
| `rust-analyzer` | Rust LSP | **rustup component** | Version-locked to the toolchain that compiles your code; nixpkgs' copy can drift from `rustc`. This is a deliberate exception to "LSP → Nix", consistent with `home.nix` already ceding Rust to rustup. |
| `codelldb` | Rust debug adapter | Mason | Mason owns DAP adapters. Also in nixpkgs as `vscode-extensions.vadimcn.vscode-lldb`, but not in scoop, so Windows needs Mason. |
| .NET SDK | C#/F# runtime | **mise** (`core:dotnet` backend) | Follows "runtimes → mise". Confirmed available: `mise registry` lists `dotnet → core:dotnet`. Per-project pinning via `.mise.toml` is the point. |
| `roslyn-ls` | C# LSP | Nix (`roslyn-ls`) | Confirmed in nixpkgs. |
| `csharpier` | C# formatter | Nix (`csharpier`) | Confirmed in nixpkgs. |
| `fsautocomplete` | F# LSP | Nix (`fsautocomplete`) | Confirmed in nixpkgs. |
| `fantomas` | F# formatter | Nix (`fantomas`) | Confirmed in nixpkgs. |
| `netcoredbg` | .NET debug adapter | Mason | Mason owns DAP adapters. Also in nixpkgs if Mason gives trouble. |
| `js-debug-adapter` | Node debug adapter | Mason | Already the intent; just needs to actually install. In nixpkgs as `vscode-js-debug`, but not in scoop and not on npm. |

### C# language server: `roslyn-ls`, not OmniSharp

`roslyn-ls` is the server behind VS Code's C# extension and is actively
developed; OmniSharp is in maintenance. Roslyn needs a `.sln` or `.csproj` to
anchor a workspace, which is normal for real projects. Wiring it up needs the
`seblyng/roslyn.nvim` plugin — the server is not a plain stdio LSP you can drop
into `lsp-config.lua`.

**Alternative:** `omnisharp` is configured out of the box by `nvim-lspconfig` and
needs no extra plugin. Fall back to it if `roslyn.nvim` fights you.

### Rust: `rustaceanvim`, not a plain `rust_analyzer` entry

`mrcjkb/rustaceanvim` handles rust-analyzer's non-standard LSP extensions
(expand macro, view HIR/MIR, runnables, `Cargo.toml` integration), wires
`codelldb` into `nvim-dap` for you, and ships a neotest adapter for `cargo test`.
A plain `rust_analyzer` entry gives you completion and diagnostics and nothing
else.

**Critical constraint:** rustaceanvim configures the LSP client itself. If
`rust_analyzer` is *also* added to `language_servers` in `lsp-config.lua` you get
two clients attached to every Rust buffer, with duplicated diagnostics. Pick one.
This plan picks rustaceanvim, so `rust_analyzer` must stay **out** of
`lsp-config.lua`.

**Alternative:** add `rust_analyzer = {}` to `language_servers` and skip the
plugin. Simpler, meaningfully less capable.

### F#: plain LSP first, `ionide-vim` only if needed

`fsautocomplete` works as an ordinary stdio LSP through the existing
`lsp-config.lua` table. `ionide/ionide-vim` adds F# Interactive integration and
`.fsproj` file-ordering commands. F# compilation is order-sensitive within a
project file, so if you end up hand-editing `.fsproj` a lot, add it later —
it is not needed to get diagnostics and completion working.

### DAP adapter installation: drop `mason-nvim-dap`

`mason-nvim-dap`'s `ensure_installed` does not work here (Part 1, item 1). Root
cause is unconfirmed — plausibly a mason.nvim v2 API change, since the installed
`mason.nvim` is from 2026-05 and `mason-nvim-dap` from 2025-10 — but rather than
chase it, replace it with about fifteen lines that call `mason-registry`
directly. Fewer moving parts, and you own the failure mode. Snippet in the
appendix.

**Alternative:** keep `mason-nvim-dap` and install adapters by hand with
`:MasonInstall` whenever you set up a new machine. Works, but silently drifts.

---

## Part 3 — The stages

Each stage is independently useful and ends in a verification you can run.
Do not start the next stage until the current one's verification passes.

### Stage 1 — Repair Node/TypeScript debugging

**Goal.** Set a breakpoint in a running Express/Nest server and hit it. Debug a
vitest test. Stop offering browser launches in backend files.

**1.1 — Restructure the DAP configuration.**

`dap.lua` is about 190 lines and will roughly triple as Rust and .NET arrive.
Split per-language configuration out now, keeping the plugin-per-file convention:

```
lua/pcf/plugins/debugging/dap.lua   -- plugin spec, dapui, keymaps, adapter install
lua/pcf/dap/javascript.lua          -- pwa-node adapter + JS/TS/JSX/TSX configs
lua/pcf/dap/rust.lua                -- Stage 2
lua/pcf/dap/dotnet.lua              -- Stage 3
```

`dap.lua`'s `config` function ends with:

```lua
require("pcf.dap.javascript").setup()
```

**1.2 — Remove `nvim-dap-vscode-js` and `mason-nvim-dap`** from the `dependencies`
list in `dap.lua`, along with the `require("dap-vscode-js").setup({...})` and
`require("mason-nvim-dap").setup({...})` blocks. Keep `mason.nvim` itself.

**1.3 — Add the adapter-install helper** (appendix A) and call it with
`{ "js-debug-adapter" }`.

**1.4 — Define the `pwa-node` adapter directly** (appendix B). Mason's
`js-debug-adapter` shim lives at
`~/.local/share/nvim/mason/bin/js-debug-adapter` and launches
`js-debug/src/dapDebugServer.js` — both confirmed present.

**1.5 — Fix the aliasing bug.** Replace the two assignment lines with
`vim.deepcopy(...)`, so browser configurations land only on the React filetypes.

**1.6 — Add the backend configurations** that are missing (appendix B):
*Attach to port 9229*, *Attach to process*, *Launch file (tsx)*, and
*Debug vitest current file*.

**1.7 — Register `neotest-jest`** alongside `neotest-vitest` in `neo-test.lua`,
so jest projects are discovered too.

**1.8 — Make the Edge path portable.** Replace the hardcoded
`/usr/bin/microsoft-edge` with a lookup that returns `nil` when Edge is absent
(`vim.fn.exepath("microsoft-edge")`), letting js-debug fall back to its own
discovery on Windows.

**Verification.**

```bash
# 1. Adapter present
ls ~/.local/share/nvim/mason/bin/js-debug-adapter

# 2. Backend filetypes no longer carry browser configs — expect 6, not 8,
#    and no "Launch Chrome"/"Launch Edge" entries
nvim --headless "+lua vim.defer_fn(function()
  local dap = require('dap')
  print('ts:', #dap.configurations.typescript,
        'tsx:', #dap.configurations.typescriptreact,
        'aliased:', tostring(dap.configurations.typescript == dap.configurations.typescriptreact))
  for _, c in ipairs(dap.configurations.typescript) do print('  ' .. c.name) end
  vim.cmd('qa!')
end, 3000)"
```

Then, in a real project: `node --inspect ./dist/main.js` in one terminal,
`<F5>` → *Attach to port 9229* in Neovim, breakpoint hits. And `<leader>td` on
a vitest test stops at a breakpoint.

---

### Stage 2 — Rust

**2.1 — Install the toolchain pieces.**

```bash
rustup component add rust-analyzer clippy rustfmt
rust-analyzer --version   # must NOT say "Unknown binary"
```

Add this to `install/install-rustup.sh` so a fresh machine gets it — the script
currently installs the toolchain and stops.

**2.2 — Add `rustaceanvim`** as `lua/pcf/plugins/lsp/rustaceanvim.lua`:

```lua
return {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- the plugin manages its own ft-based loading
}
```

Register it in `init.lua` under the `lsp` group. Leave `rust_analyzer` **out** of
`lsp-config.lua` (see Part 2).

**2.3 — Point rustaceanvim at codelldb.** Add `"codelldb"` to the adapter-install
list from Stage 1.3. rustaceanvim auto-detects Mason's codelldb, so no explicit
`vim.g.rustaceanvim.dap` block should be needed — verify before adding one.

**2.4 — Treesitter.** `rust` is already installed; add `toml` for `Cargo.toml`.

**2.5 — Formatting.** rustaceanvim routes formatting through rust-analyzer's
`rustfmt`, and conform's `lsp_format = "fallback"` already picks that up for
filetypes with no explicit formatter. Add an explicit `rust = { "rustfmt" }`
entry only if the fallback misbehaves — conform has a built-in `rustfmt`
definition, so it is a one-line addition if you want it explicit.

**2.6 — Testing.** rustaceanvim ships a neotest adapter. In `neo-test.lua`:

```lua
adapters = {
    require("neotest-vitest"),
    require("neotest-jest"),
    require("rustaceanvim.neotest"),
},
```

**Verification.** In any cargo project: hover works, `:RustLsp runnables` lists
targets, `<leader>tt` on a `#[test]` runs it, `<F5>` on a binary target stops at a
breakpoint.

---

### Stage 3 — .NET foundation

Shared prerequisite for Stages 4 and 5. Nothing language-specific here.

**3.1 — Install the SDK via mise.** In `mise/.config/mise/config.toml`:

```toml
[tools]
dotnet = "9"
```

```bash
mise install
dotnet --info
```

**3.2 — Treesitter.** Add `c_sharp` and `fsharp` to `ensure_installed` in
`treesitter.lua`.

Note the file no longer has an `ensure_installed` table — that was a `master`
branch option. Add the parsers to the `PARSERS` list at the top of
`treesitter.lua` instead; `install_missing_parsers()` picks them up on the next
start and installs whatever is absent. The same applies to `toml` in Stage 2.4.

**3.3 — Debug adapter.** Add `"netcoredbg"` to the adapter-install list, and
create `lua/pcf/dap/dotnet.lua` with the `coreclr` adapter and launch
configuration (appendix C). The configuration prompts for a DLL path, defaulting
to `bin/Debug/`, and is registered for both `cs` and `fsharp` filetypes.

**Verification.**

```bash
dotnet --list-sdks
ls ~/.local/share/nvim/mason/bin/netcoredbg
nvim --headless "+TSInstallSync c_sharp fsharp" "+qa!"
```

---

### Stage 4 — C#

**4.1 — Add the server to `home.nix`**, under the LSP block:

```nix
roslyn-ls                           # C# language server (Roslyn)
csharpier                           # C# formatter
```

```bash
cd ~/.config/nix && home-manager switch --flake .
```

**4.2 — Add `seblyng/roslyn.nvim`** as `lua/pcf/plugins/lsp/roslyn.lua` and
register it in `init.lua`.

> **Verify the wiring against the plugin's current README before writing this
> file.** roslyn.nvim moved to Neovim's native `vim.lsp.config("roslyn", ...)`
> mechanism during 2025 and the setup shape changed with it. The server binary
> from nixpkgs is `Microsoft.CodeAnalysis.LanguageServer`; find its exact path
> with `readlink -f $(which Microsoft.CodeAnalysis.LanguageServer)` after the
> home-manager switch, and pass it as `cmd`.

**4.3 — Formatting.** conform ships a built-in `csharpier` definition, so in
`format.lua` this is one line in `formatters_by_ft`: `cs = { "csharpier" }`.

**4.4 — Testing (optional).** `Issafalcon/neotest-dotnet` covers xunit and nunit.
Add it to `neo-test.lua`'s dependencies and adapters.

**Verification.** Open a `.cs` file in a project with a `.csproj`: `:checkhealth
lsp` shows the roslyn client attached, `gd` navigates, `<leader>hf` formats,
`<F5>` starts a `coreclr` session against the built DLL.

---

### Stage 5 — F#

**5.1 — Add to `home.nix`:**

```nix
fsautocomplete                      # F# language server
fantomas                            # F# formatter
```

**5.2 — Add to `lsp-config.lua`.** `fsautocomplete` is a plain stdio server, so it
is one entry in the existing `language_servers` table — the loop at the bottom of
the file picks it up automatically:

```lua
fsautocomplete = {
    cmd = { "fsautocomplete", "--adaptive-lsp-server-enabled" },
    settings = {
        FSharp = {
            keywordsAutocomplete = true,
            externalAutocomplete = false,
            unionCaseStubGeneration = true,
            recordStubGeneration = true,
            interfaceStubGeneration = true,
        },
    },
},
```

**5.3 — Formatting.** conform ships a built-in `fantomas` definition, so this is
one line in `formatters_by_ft`:

```lua
fsharp = { "fantomas" },
```

Note that conform's `fantomas` runs `fantomas $FILENAME` with `stdin = false` —
it rewrites the file on disk rather than streaming through stdin. That is
correct for fantomas, but it means format-on-save writes twice; if that causes
trouble with your undo history, formatting F# on demand via `<leader>hf` instead
of on save is the escape hatch.

**5.4 — F# Interactive (optional).** Add `ionide/ionide-vim` if you want FSI and
`.fsproj` ordering commands. Skip on the first pass.

**Verification.** Open a `.fs` file in a project with an `.fsproj`: diagnostics
appear, completion works, `<leader>hf` reformats, `<F5>` debugs via the `coreclr`
configuration from Stage 3.

---

### Stage 6 — Cross-cutting polish and repo updates

**6.1 — Fill the gaps in the DAP keymaps.** The current set has no terminate, no
run-last, and no expression evaluation — all of which you will want constantly
once you are debugging servers:

```lua
map("n", "<leader>dt", dap.terminate,   { desc = "[Debugger] Terminate session" })
map("n", "<leader>dl", dap.run_last,    { desc = "[Debugger] Re-run last configuration" })
map("n", "<leader>dr", dap.repl.toggle, { desc = "[Debugger] Toggle REPL" })
map({ "n", "v" }, "<leader>de", dapui.eval, { desc = "[Debugger] Evaluate expression" })
```

Note `<leader>de` currently collides with the "Delete to end of line" mapping in
`keymaps.lua:59`. Pick a different key for one of them.

**6.2 — Name the which-key groups** so `<leader>d` and `<leader>t` are
discoverable. `which-key.nvim` is set up with an empty config; add a `spec`.

**6.3 — Update the repo's own documentation**, since the boundary tables are
what an agent reads first:

- `CLAUDE.md` and `AGENTS.md` — add the rustup exception for `rust-analyzer` to
  the package-manager boundary table.
- `docs/strategy.md` — record why the .NET SDK is a mise runtime and why Rust
  tooling is exempt from the Nix rule.
- `nvim/.config/nvim/AGENTS.md` — the test section names only vitest; add rust
  and dotnet adapters once Stages 2 and 4 land.

**6.4 — Optional, for large TS monorepos.** Consider swapping `ts_ls` for
`vtsls`, which handles big workspaces and monorepo project references
considerably better. It is a drop-in replacement in `language_servers` plus a
`vtsls` entry in `home.nix`. Unrelated to the backend goal — listed because you
mentioned React/TypeScript is the day job.

---

## Resolved: treesitter was running an unconfigured `main` branch

Found while verifying Stage 1, fixed in `26277c0`. Recorded here because the
failure mode is easy to reintroduce.

The plugin spec pinned no branch, so lazy.nvim followed nvim-treesitter when
upstream renamed its default branch from `master` to `main`. The `main` branch is
a rewrite whose `setup()` accepts only `install_dir`, so `ensure_installed`,
`indent` and `textobjects` were all accepted and silently discarded.

Highlighting *appeared* to work only because snacks.nvim's `quickfile` module
calls `vim.treesitter.start` on files named on the command line. Files opened
during a session had none, falling back to regex syntax:

```
startup buffer   ft=typescript   highlighter=true
runtime buffer   ft=javascript   highlighter=false
```

`treesitter.lua` now drives highlighting, indentation and parser installation
explicitly, and both nvim-treesitter and nvim-treesitter-textobjects pin
`branch = "main"`.

Two consequences for later stages:

- **Adding a parser** means adding to the `PARSERS` list in `treesitter.lua`,
  not to an `ensure_installed` table.
- **The tree-sitter CLI (>= 0.26.1) is now a hard requirement**, because `main`
  shells out to `tree-sitter build`. Provisioned in `home.nix` (Linux) and
  `packages/scoop-packages.txt` (Windows); macOS would need
  `brew install tree-sitter`.

Still outstanding, deliberately left alone: the on-disk plugin set has drifted
ahead of `lazy-lock.json` for roughly fifteen plugins, and `nvim-lspconfig`'s
locked commit does not match what is checked out. Running `:Lazy sync` will
reconcile all of it at once — do that deliberately, in its own commit.

---

## Environment breadth (done)

Filled the gaps found when auditing whether the setup covered professional
frontend and backend work. Verified on Linux; the Nix profile must be activated
first (`cd ~/.config/nix && home-manager switch --flake .`).

All nineteen servers were verified attaching to real files with correct root
markers — including `elixirls` on a `mix new` project (it takes ~15 s on first
start while it compiles) and `elp` on a `rebar.config` project.

**Language servers added** (`home.nix` + `lsp-config.lua`): `bashls`, `yamlls`,
`dockerls`, `taplo`, `tailwindcss`, `graphql`, `basedpyright`, `ruff`,
`elixirls`, `elp`, `zls`. Nineteen servers enabled in total.

**`ts_ls` replaced by `vtsls`.** Better on monorepos and project references. The
nixpkgs build bundles TypeScript 5.9.3 including `tsserver`, so it is
self-contained. `typescript-language-server` was removed from `home.nix`.
**Never enable both** — every buffer would get two clients and doubled
diagnostics. Verified: 19 enabled, `ts_ls` not among them.

**Tailwind is constrained on purpose.** lspconfig falls back to `.git` as a root
marker (Tailwind v4 makes `tailwind.config.*` optional), which starts a **168 MB**
server in every repository whether or not it uses Tailwind — measured, not
estimated. `lsp-config.lua` overrides `root_dir` to drop that fallback while
keeping `package.json` detection, which catches v3 and v4 alike. If a genuine
Tailwind project ever fails to attach, that override is the first place to look.

**Schema validation.** `SchemaStore.nvim` feeds `jsonls` (1459 schemas) and
`yamlls` (1360), so `package.json`, `tsconfig.json`, GitHub Actions workflows and
compose files are validated while editing. `yamlls`' built-in schema store is
disabled so the two do not fight.

**Parsers: 9 to 22.** Added `bash`, `css`, `scss`, `yaml`, `dockerfile`, `toml`,
`sql`, `graphql`, `python`, `elixir`, `erlang`, `heex`, `zig`. Before this, every
one of those filetypes fell back to regex highlighting.

**Formatters** (`conform`): `shfmt` for shell, `taplo` for TOML, `sqlfluff` for
SQL, `ruff` for Python, `mix` for Elixir, `zigfmt` for Zig, prettier for SCSS.
Note `sqlfluff` sets `require_cwd`, so it no-ops unless the project has a
`.sqlfluff` or `pyproject.toml` — SQL is never reformatted by surprise.

**CLI**: `gh`, `sqlite`, `postgresql` (for `psql`), `shellcheck` (picked up
automatically by `bashls`).

### On the mise runtimes

Python, Erlang, Elixir and Zig are installed by mise but had no editor support at
all. Tooling now exists for each. They are not yet used in anger, so the servers
are configured but unproven against a real project — `elixirls` needs a
`mix.exs`, `elp` needs `rebar.config`, and `basedpyright` wants a
`pyproject.toml` to resolve imports properly. Expect to tune settings when the
first real project appears rather than assuming these are finished.

### Deliberately not done

- **SQL language server.** `sqls` and `postgres_lsp` both need per-connection
  configuration to be useful; without a database they add little over the parser
  and formatter. Revisit when there is a database to point at.
- **A Neovim REST client** (`kulala.nvim` and similar). Postman and Insomnia are
  already installed and cover this.

---

## Stage 2 notes (Rust, done)

`rust-analyzer` now comes from `rustup component add`, so it is version-locked to
the toolchain (1.98.1 for both). `install/install-rustup.sh` installs
`rust-analyzer`, `clippy` and `rustfmt` idempotently, so a fresh machine gets
them without a manual step.

`rustaceanvim` owns the Rust LSP client. `rust_analyzer` is deliberately absent
from `lsp-config.lua`; verified exactly one client attaches. Keymaps live under
`<leader>r` (`ra` code action, `rr` runnables, `rd` debuggables, `rm` expand
macro, `rc` open Cargo.toml, `re` explain error).

`check.command = "clippy"` is set, so the editor shows the same lints
`cargo clippy` does. Verified against CLI ground truth: `clippy::let_and_return`
appears in-editor with source `clippy`. Note a hard type error aborts the clippy
run, so lints disappear until the file compiles — that is cargo's behaviour, not
a misconfiguration.

Formatting needs no conform entry: `lsp_format = "fallback"` routes Rust through
rust-analyzer's rustfmt. Verified on save.

### Things that cost time here, recorded so they do not again

- **`mason.setup()` was not being called.** Removing the `mason.nvim` dependency
  from `lsp-config.lua` in the previous stage also removed its `config = true`,
  which was the only thing calling `mason.setup()`. The registry then exposed
  **1** package instead of 594, so `codelldb` "did not exist" and
  `ensure_adapters` skipped it silently. Fixed by restoring `config = true` on
  the dependency in `dap.lua`. `ensure_adapters` now emits a warning for an
  unresolvable package rather than skipping quietly.
- **`rustaceanvim`'s DAP adapter is a lazy getter**, not a nvim-dap callback
  adapter: `internal.dap.adapter` is `function() return adapter_table end`.
  Assigning it straight to `dap.adapters.codelldb` hangs at "Starting adapter".
  Let rustaceanvim drive debugging via `<leader>rd`; do not wire it manually.
- **neotest discovery looks broken headlessly and is not.** Querying
  `neotest.state.positions()` from a script returns nothing because neotest's own
  discovery has not been triggered. Calling the adapter directly inside `nio.run`
  returns `file:main.rs, namespace:tests, test:adds_two_numbers` as expected.
- **`vim.lsp.get_buffers_by_client_id() is deprecated`** on every Rust buffer
  comes from `rustaceanvim/lua/rustaceanvim/server_status.lua:52`. Upstream's to
  fix; cosmetic.

### Verified

rust-analyzer attaches (exactly one client), treesitter highlights, `:RustLsp`
exists, rust-analyzer returns 6 runnables including the test, clippy diagnostics
match the CLI, format-on-save applies rustfmt, the neotest adapter discovers
tests, `:checkhealth rustaceanvim` is all-OK including "debug adapter: found",
and a breakpoint in `add()` is hit under codelldb with Rust formatters loaded
from the rustup toolchain.

---

## Part 4 — Agent handoff

*Read this section if you are an AI agent continuing this work.*

### Before anything else

1. Read `AGENTS.md` at the repo root. Its first rule is **ask the user for
   confirmation before making changes**, even obvious ones. That rule governs
   this work; do not batch-apply the stages below without checking in.
2. Read the progress checklist at the top of this file to find the current stage.
3. Re-run the audit commands in "State probes" below. This document was written
   on 2026-09-05 against commit `c601cf3`; anything here may have gone stale.

### Repo invariants you must not break

- **Two OS targets from one tree.** `nvim/.config/nvim/` is consumed by GNU Stow
  on Linux *and* by explicit symlinks on Windows
  (`install/windows/setup-windows-symlinks.ps1`). Any absolute path or
  Linux-only binary reference in Lua must be guarded — `vim.fn.exepath()` or
  `vim.fn.has("win32")`. The existing hardcoded `/usr/bin/microsoft-edge` is the
  bug this rule exists to prevent; do not add more.
- **Package-manager boundaries** are load-bearing, documented in `CLAUDE.md`.
  LSP/formatters/linters → Nix `home.nix`. DAP adapters → Mason. Runtimes → mise.
  System/GUI → apt. Stage 2 introduces one deliberate exception (rust-analyzer
  via rustup); it must be documented in the boundary table, not left implicit.
- **Neovim style**, from `nvim/.config/nvim/AGENTS.md`: tabs at width 4 for Lua,
  160-column lines, double quotes, `pcall` around every `require` of an optional
  module with an early return on failure, modules returned as `M`, keymaps
  through `require("pcf.utils").map()` and always with a `desc`, plugin files
  returning lazy.nvim spec tables. Run `stylua` before finishing.

  One caveat: `lsp-config.lua` is the single file written with **2-space** indent
  while every other plugin file uses tabs, and `.stylua.toml` specifies
  `indent_type = "Tabs"`. Running `stylua` across the tree will therefore
  reformat that whole file. Either convert it deliberately in its own commit, or
  restrict `stylua` to the files you actually touched — do not let an unrelated
  whitespace diff ride along with a feature change.
- **Adding a plugin takes two edits**: the spec file under
  `lua/pcf/plugins/<category>/`, and a `plugin("<category>.<name>")` line in
  `init.lua`. The init list is explicit — there is no directory auto-loading, so
  a new file alone does nothing.

### State probes

```bash
# Neovim + LSP API generation
nvim --version | head -1

# Which language servers are wired up
sed -n '/language_servers = {/,/^    }/p' nvim/.config/nvim/lua/pcf/plugins/lsp/lsp-config.lua

# Which DAP adapters are actually installed on disk
ls ~/.local/share/nvim/mason/bin/ 2>/dev/null || echo "none"

# Toolchains
rust-analyzer --version; dotnet --list-sdks; mise list

# Does the aliasing bug still exist? (Stage 1 fixes this)
nvim --headless "+lua vim.defer_fn(function()
  local d = require('dap')
  print('aliased:', tostring(d.configurations.typescript == d.configurations.typescriptreact))
  vim.cmd('qa!')
end, 3000)"
```

### Things that will bite you

- **Duplicate Rust LSP clients.** rustaceanvim attaches its own `rust_analyzer`.
  If someone also adds `rust_analyzer = {}` to `language_servers`, the loop at
  the bottom of `lsp-config.lua` calls `vim.lsp.enable()` on it and you get two
  clients per buffer with doubled diagnostics. Symptom: every warning appears
  twice. Check `:LspInfo` / `:checkhealth lsp` before debugging anything else.
- **`mason-nvim-dap`'s `ensure_installed` silently does nothing** in this setup —
  verified, not suspected. Do not "fix" a missing adapter by trusting it; either
  use the helper in appendix A or install by hand and confirm the file exists on
  disk.
- **`roslyn.nvim`'s setup API changed** during 2025 as it moved onto Neovim's
  native `vim.lsp.config`. Any snippet you recall from training data is likely
  the old shape. Read the current README; do not guess.
- **`fantomas` stdin flags** vary across major versions. Run `fantomas --help`.
- **`nvim-treesitter` tracks the `main` branch, pinned.** The two branches have
  incompatible APIs and most snippets in circulation — including, most likely,
  the one you are about to recall — are written for `master`. If you find
  yourself typing `ensure_installed`, `highlight = { enable = true }` or a
  `textobjects` block into `treesitter.lua`, stop: none of those exist on `main`.
  Do not remove the `branch = "main"` pins.
- **Do not run `home-manager switch` unprompted.** It mutates the user's profile.
  Edit `home.nix`, then tell the user the command to run.
- **`.install-state` is gitignored** and tracks completed install steps. If you
  change `install/install-rustup.sh` (Stage 2.1), the user must re-run it with
  `./install.sh rustup --force` — completed steps are skipped otherwise.

### Definition of done for a stage

A stage is done when its **Verification** block passes, `stylua` is clean, and
the checklist at the top of this file is ticked. Update the checklist in the same
commit as the code.

---

## Appendix

### A — Mason adapter install helper

Replaces `mason-nvim-dap`. Lives near the top of `dap.lua`'s `config` function.

```lua
-- mason-nvim-dap's ensure_installed does not fire with mason.nvim v2, so
-- install DAP adapters directly through the registry.
local function ensure_dap_adapters(names)
    local ok, registry = pcall(require, "mason-registry")
    if not ok then
        return
    end

    registry.refresh(function()
        for _, name in ipairs(names) do
            local found, pkg = pcall(registry.get_package, name)
            if found and not pkg:is_installed() then
                vim.notify("Installing DAP adapter: " .. name, vim.log.levels.INFO)
                pkg:install()
            end
        end
    end)
end

ensure_dap_adapters({ "js-debug-adapter" }) -- add "codelldb", "netcoredbg" per stage
```

### B — Node adapter and backend configurations

```lua
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"

for _, adapter in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge" }) do
    dap.adapters[adapter] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
            command = mason_bin .. "js-debug-adapter",
            args = { "${port}" },
        },
    }
end

local skip_files = { "<node_internals>/**", "**/node_modules/**" }

dap.configurations.typescript = {
    {
        type = "pwa-node",
        request = "attach",
        name = "Attach to port 9229",
        port = 9229,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        skipFiles = skip_files,
        restart = true,
    },
    {
        type = "pwa-node",
        request = "launch",
        name = "Launch file (tsx)",
        runtimeExecutable = "tsx",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        skipFiles = skip_files,
        console = "integratedTerminal",
    },
    {
        type = "pwa-node",
        request = "launch",
        name = "Debug vitest current file",
        program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
        args = { "run", "${file}" },
        cwd = "${workspaceFolder}",
        autoAttachChildProcesses = true,
        smartStep = true,
        skipFiles = skip_files,
        console = "integratedTerminal",
    },
    -- keep the existing "Launch file" and "Attach" (pick_process) entries
}

-- deepcopy, NOT assignment -- see Part 1, item 3
dap.configurations.typescriptreact = vim.deepcopy(dap.configurations.typescript)
dap.configurations.javascriptreact = vim.deepcopy(dap.configurations.javascript)
```

### C — .NET (`coreclr`) adapter

```lua
dap.adapters.coreclr = {
    type = "executable",
    command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
    args = { "--interpreter=vscode" },
}

local dotnet_config = {
    {
        type = "coreclr",
        name = "Launch - netcoredbg",
        request = "launch",
        program = function()
            return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
        end,
    },
    {
        type = "coreclr",
        name = "Attach - netcoredbg",
        request = "attach",
        processId = require("dap.utils").pick_process,
    },
}

dap.configurations.cs = dotnet_config
dap.configurations.fsharp = vim.deepcopy(dotnet_config)
```

### D — Files this plan touches

| File | Stages |
|---|---|
| `nvim/.config/nvim/lua/pcf/plugins/debugging/dap.lua` | 1, 2, 3, 6 |
| `nvim/.config/nvim/lua/pcf/dap/{javascript,rust,dotnet}.lua` | 1, 2, 3 *(new)* |
| `nvim/.config/nvim/lua/pcf/plugins/lsp/lsp-config.lua` | 5 |
| `nvim/.config/nvim/lua/pcf/plugins/lsp/{rustaceanvim,roslyn}.lua` | 2, 4 *(new)* |
| `nvim/.config/nvim/lua/pcf/plugins/lsp/format.lua` | 2, 4, 5 |
| `nvim/.config/nvim/lua/pcf/plugins/editor/treesitter.lua` | 2, 3 |
| `nvim/.config/nvim/lua/pcf/plugins/testing/neo-test.lua` | 1, 2, 4 |
| `nvim/.config/nvim/lua/pcf/plugins/ui/which-key.lua` | 6 |
| `nvim/.config/nvim/init.lua` | 2, 4 |
| `nix/.config/nix/home.nix` | 4, 5 |
| `mise/.config/mise/config.toml` | 3 |
| `install/install-rustup.sh` | 2 |
| `CLAUDE.md`, `AGENTS.md`, `docs/strategy.md` | 6 |

-- https://github.com/microsoft/vscode-js-debug
--
-- Node and browser debug configurations.
--
-- Deliberately framework-agnostic: the attach configurations talk to Node's
-- inspector protocol, so anything started with `--inspect` works the same way
-- (Express, Fastify, Hono, a bare script, a build tool). Nothing here knows or
-- cares which HTTP framework a project uses.

local M = {}

-- Paths inside node_modules and Node's own internals are never interesting when
-- stepping through application code.
local SKIP_FILES = { "<node_internals>/**", "**/node_modules/**" }

local NODE_INSPECTOR_PORT = 9229

-- Mason installs js-debug-adapter as a shim in mason/bin.
local function adapter_command()
  local bin = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter"

  if require("pcf.utils").is_windows_platform() then
    bin = bin .. ".cmd"
  end

  return bin
end

-- Returns the first candidate found on PATH, or nil so js-debug falls back to
-- its own browser discovery (which is the only thing that works on Windows).
local function find_executable(candidates)
  for _, name in ipairs(candidates) do
    local path = vim.fn.exepath(name)

    if path ~= "" then
      return path
    end
  end

  return nil
end

-- Resolve a test runner inside node_modules, walking up from the current file.
-- A hardcoded ${workspaceFolder}/node_modules path breaks in monorepos and pnpm
-- layouts, where the binary is hoisted to the repo root rather than sitting in
-- the package being edited.
local function resolve_from_node_modules(candidates)
  return function()
    local start = vim.fn.expand("%:p:h")

    if start == "" then
      start = vim.fn.getcwd()
    end

    local roots = vim.fs.find("node_modules", {
      path = start,
      upward = true,
      type = "directory",
      limit = math.huge,
    })

    for _, root in ipairs(roots) do
      for _, candidate in ipairs(candidates) do
        local path = root .. "/" .. candidate

        if vim.fn.filereadable(path) == 1 then
          return path
        end
      end
    end

    -- Let the adapter report a missing-file error against the obvious path.
    return vim.fn.getcwd() .. "/node_modules/" .. candidates[1]
  end
end

-- Best-effort guess at the dev server port by scanning package.json scripts,
-- then confirm with the user. Covers Vite (5173), Next (3000) and explicit
-- --port flags without hardcoding any of them.
local function get_dev_server_port()
  local package_json_path = vim.fn.getcwd() .. "/package.json"
  local default_port = "3000"

  if vim.fn.filereadable(package_json_path) == 1 then
    local ok, package_data = pcall(vim.fn.json_decode, vim.fn.readfile(package_json_path))

    if ok and package_data.scripts then
      for _, script in pairs(package_data.scripts) do
        local port = script:match("%-%-port[=%s]+(%d+)") or script:match("PORT[=%s]+(%d+)")

        if port then
          default_port = port
          break
        end
      end
    end
  end

  local port = vim.fn.input("Dev server port: ", default_port)

  return port ~= "" and port or default_port
end

local function register_adapters(dap)
  local command = adapter_command()

  for _, adapter in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge" }) do
    dap.adapters[adapter] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = command,
        args = { "${port}" },
      },
    }
  end
end

-- Configurations shared by every Node filetype. `is_typescript` adds entries
-- that only make sense when the file needs transpiling.
local function node_configurations(is_typescript)
  local configurations = {
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to Node (--inspect)",
      port = function()
        local port = vim.fn.input("Inspector port: ", tostring(NODE_INSPECTOR_PORT))

        return tonumber(port) or NODE_INSPECTOR_PORT
      end,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = SKIP_FILES,
      -- Reconnect when the process restarts, so watch-mode dev servers
      -- keep the session alive instead of dropping it on every save.
      restart = true,
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to Node process...",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = SKIP_FILES,
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = SKIP_FILES,
      console = "integratedTerminal",
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Run npm script...",
      runtimeExecutable = "npm",
      runtimeArgs = function()
        local script = vim.fn.input("npm script: ", "dev")

        return { "run", script ~= "" and script or "dev" }
      end,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = SKIP_FILES,
      -- npm spawns the real process as a child; without this the debugger
      -- attaches to npm itself and never reaches application code.
      autoAttachChildProcesses = true,
      console = "integratedTerminal",
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Debug vitest (current file)",
      program = resolve_from_node_modules({ "vitest/vitest.mjs", ".bin/vitest" }),
      -- vitest farms test files out to worker threads by default, where
      -- breakpoints bind unreliably; one process is what you want when
      -- debugging, whatever the pool is configured to be.
      args = { "run", "--no-file-parallelism", "${file}" },
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = SKIP_FILES,
      autoAttachChildProcesses = true,
      smartStep = true,
      console = "integratedTerminal",
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Debug jest (current file)",
      program = resolve_from_node_modules({ "jest/bin/jest.js", ".bin/jest" }),
      args = { "--runInBand", "--no-coverage", "${file}" },
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = SKIP_FILES,
      console = "integratedTerminal",
    },
  }

  if is_typescript then
    -- Node 22 cannot execute TypeScript directly, so launching a .ts file
    -- needs a loader. tsx is the least opinionated of the options.
    table.insert(configurations, 3, {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file (tsx)",
      runtimeExecutable = "tsx",
      program = "${file}",
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = SKIP_FILES,
      console = "integratedTerminal",
    })
  end

  return configurations
end

-- Browser configurations belong only on the React filetypes.
local function browser_configurations()
  local configurations = {}

  local browsers = {
    {
      type = "pwa-msedge",
      label = "Edge",
      runtimeExecutable = find_executable({ "microsoft-edge", "microsoft-edge-stable", "msedge" }),
    },
    {
      type = "pwa-chrome",
      label = "Chrome",
      runtimeExecutable = find_executable({ "google-chrome", "google-chrome-stable", "chromium", "chrome" }),
    },
  }

  for _, browser in ipairs(browsers) do
    table.insert(configurations, {
      type = browser.type,
      request = "launch",
      name = "Launch " .. browser.label .. " (prompt for port)",
      url = function()
        return "http://localhost:" .. get_dev_server_port()
      end,
      webRoot = "${workspaceFolder}",
      sourceMaps = true,
      runtimeExecutable = browser.runtimeExecutable,
    })

    for _, port in ipairs({ "3000", "5173" }) do
      table.insert(configurations, {
        type = browser.type,
        request = "launch",
        name = "Launch " .. browser.label .. " (port " .. port .. ")",
        url = "http://localhost:" .. port,
        webRoot = "${workspaceFolder}",
        sourceMaps = true,
        runtimeExecutable = browser.runtimeExecutable,
      })
    end
  end

  return configurations
end

function M.setup()
  local ok, dap = pcall(require, "dap")

  if not ok then
    return
  end

  register_adapters(dap)

  dap.configurations.javascript = node_configurations(false)
  dap.configurations.typescript = node_configurations(true)

  -- deepcopy, never assignment: sharing the table would make the browser
  -- configurations below leak back into the plain Node filetypes.
  dap.configurations.javascriptreact = vim.deepcopy(dap.configurations.javascript)
  dap.configurations.typescriptreact = vim.deepcopy(dap.configurations.typescript)

  for _, configuration in ipairs(browser_configurations()) do
    table.insert(dap.configurations.javascriptreact, configuration)
    table.insert(dap.configurations.typescriptreact, vim.deepcopy(configuration))
  end
end

return M

-- JavaScript React Snippets - Using shared modules
local luasnip_ok, _ = pcall(require, "luasnip")
if not luasnip_ok then
    return
end

-- Import shared snippet modules
local console_snippets = require("pcf.snippets.common.console")
local function_snippets = require("pcf.snippets.common.functions")
local test_snippets = require("pcf.snippets.common.testing")
local react_snippets = require("pcf.snippets.common.react")
local snippet_utils = require("pcf.snippets.common.utils")

-- Combine all the snippets for JavaScript React
snippet_utils.add_snippets_for_filetype(
    "javascriptreact",
    console_snippets,
    function_snippets.basic,
    test_snippets,
    react_snippets.js
)

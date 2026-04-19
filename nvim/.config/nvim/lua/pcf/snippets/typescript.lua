-- TypeScript Snippets - Using shared modules
local luasnip_ok, _ = pcall(require, "luasnip")
if not luasnip_ok then
    return
end

-- Import shared snippet modules
local console_snippets = require("pcf.snippets.common.console")
local function_snippets = require("pcf.snippets.common.functions")
local test_snippets = require("pcf.snippets.common.testing")
local typescript_snippets = require("pcf.snippets.common.typescript")
local snippet_utils = require("pcf.snippets.common.utils")

-- Combine all the snippets for TypeScript
snippet_utils.add_snippets_for_filetype(
    "typescript",
    console_snippets,
    function_snippets.basic,
    function_snippets.typed,
    test_snippets,
    typescript_snippets
)

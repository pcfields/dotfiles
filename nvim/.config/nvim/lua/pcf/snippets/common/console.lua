-- Common Console Snippets
-- Shared console logging snippets for JavaScript, TypeScript, and React

local luasnip_ok, luasnip = pcall(require, "luasnip")
if not luasnip_ok then
    return {}
end

local snippet = luasnip.snippet
local insert_node = luasnip.insert_node
local fmt = require("luasnip.extras.fmt").fmt

-- Export console snippets that can be reused across different file types
local console_snippets = {
    snippet("cl", fmt("console.log({});", { insert_node(1, "value") })),
    snippet("clo", fmt("console.log({{ {} }});", { insert_node(1, "name") })),
    snippet("ce", fmt("console.error({});", { insert_node(1, "error") })),
    snippet("cw", fmt("console.warn({});", { insert_node(1, "warning") })),
    snippet("cd", fmt("console.debug({});", { insert_node(1, "debug") })),
    snippet("ct", fmt("console.table({});", { insert_node(1, "data") })),
}

return console_snippets

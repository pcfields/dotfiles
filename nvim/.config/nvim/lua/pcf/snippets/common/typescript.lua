-- TypeScript-specific Snippets
-- Type definitions and TypeScript-only snippets

local luasnip_ok, luasnip = pcall(require, "luasnip")
if not luasnip_ok then
    return {}
end

local snippet = luasnip.snippet
local insert_node = luasnip.insert_node
local fmt = require("luasnip.extras.fmt").fmt

-- TypeScript type snippets
local typescript_snippets = {
    snippet("type", fmt("type {} = {};", {
        insert_node(1, "Name"),
        insert_node(2, "string | number")
    })),

    snippet("interface", fmt("interface {} {{\n\t{}\n}}", {
        insert_node(1, "Name"),
        insert_node(2, "")
    })),

    snippet("enum", fmt("enum {} {{\n\t{}\n}}", {
        insert_node(1, "Name"),
        insert_node(2, "")
    })),
}

return typescript_snippets

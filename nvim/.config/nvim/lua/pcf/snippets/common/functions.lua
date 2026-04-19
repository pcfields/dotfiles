-- Common Function Snippets
-- Shared function snippets for JavaScript, TypeScript, and React

local luasnip_ok, luasnip = pcall(require, "luasnip")
if not luasnip_ok then
    return {}
end

local snippet = luasnip.snippet
local insert_node = luasnip.insert_node
local fmt = require("luasnip.extras.fmt").fmt

-- Basic function snippets (no types)
local basic_function_snippets = {
    snippet("fn", fmt("function {}({}) {{\n\t{}\n}}", {
        insert_node(1, "name"),
        insert_node(2, ""),
        insert_node(3, "")
    })),

    snippet("af", fmt("const {} = ({}) => {{\n\t{}\n}};", {
        insert_node(1, "name"),
        insert_node(2, ""),
        insert_node(3, "")
    })),

    snippet("afs", fmt("const {} = ({}) => {};", {
        insert_node(1, "name"),
        insert_node(2, ""),
        insert_node(3, "")
    })),
}

-- Typed function snippets (for TypeScript)
local typed_function_snippets = {
    snippet("fnt", fmt("function {}({}): {} {{\n\t{}\n}}", {
        insert_node(1, "name"),
        insert_node(2, "param: type"),
        insert_node(3, "ReturnType"),
        insert_node(4, "")
    })),

    snippet("aft", fmt("const {} = ({}): {} => {{\n\t{}\n}};", {
        insert_node(1, "name"),
        insert_node(2, "param: type"),
        insert_node(3, "ReturnType"),
        insert_node(4, "")
    })),

    snippet("afst", fmt("const {} = ({}): {} => {};", {
        insert_node(1, "name"),
        insert_node(2, "param: type"),
        insert_node(3, "ReturnType"),
        insert_node(4, "")
    })),
}

return {
    basic = basic_function_snippets,
    typed = typed_function_snippets,
}

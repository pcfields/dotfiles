-- Common Test Snippets
-- Shared testing snippets for JavaScript, TypeScript, and React

local luasnip_ok, luasnip = pcall(require, "luasnip")
if not luasnip_ok then
    return {}
end

local snippet = luasnip.snippet
local insert_node = luasnip.insert_node
local fmt = require("luasnip.extras.fmt").fmt

-- Test block snippets
local test_snippets = {
    snippet("desc", fmt("describe('{}', () => {{\n\t{}\n}});", {
        insert_node(1, "description"),
        insert_node(2, "")
    })),

    snippet("it", fmt("it('{}', () => {{\n\t{}\n}});", {
        insert_node(1, "should do something"),
        insert_node(2, "")
    })),

    snippet("test", fmt("test('{}', () => {{\n\t{}\n}});", {
        insert_node(1, "should do something"),
        insert_node(2, "")
    })),

    snippet("dt", fmt("describe('{}', () => {{\n\ttest('{}', () => {{\n\t\t{}\n\t}});\n}});", {
        insert_node(1, "description"),
        insert_node(2, "should do something"),
        insert_node(3, "")
    })),

    -- Async test blocks
    snippet("ita", fmt("it('{}', async () => {{\n\t{}\n}});", {
        insert_node(1, "should do something"),
        insert_node(2, "")
    })),

    snippet("testa", fmt("test('{}', async () => {{\n\t{}\n}});", {
        insert_node(1, "should do something"),
        insert_node(2, "")
    })),
}

return test_snippets

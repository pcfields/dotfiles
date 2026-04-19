-- Snippet utility functions
-- Helper functions for combining and managing snippets

local luasnip_ok, luasnip = pcall(require, "luasnip")
if not luasnip_ok then
    return {}
end

local M = {}

-- Combine multiple snippet tables into one
-- Usage: combine_snippets(snippets1, snippets2, snippets3, ...)
function M.combine_snippets(...)
    local combined = {}
    local snippet_tables = { ... }

    for _, snippet_table in ipairs(snippet_tables) do
        if type(snippet_table) == "table" then
            for _, snippet in ipairs(snippet_table) do
                table.insert(combined, snippet)
            end
        end
    end

    return combined
end

-- Add snippets for a specific filetype using combined snippet tables
-- Usage: add_snippets_for_filetype("javascript", console_snippets, function_snippets)
function M.add_snippets_for_filetype(filetype, ...)
    local combined = M.combine_snippets(...)
    luasnip.add_snippets(filetype, combined)
end

return M

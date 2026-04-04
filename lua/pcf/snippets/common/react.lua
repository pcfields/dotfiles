-- React-specific Snippets
-- React components and hooks

local luasnip_ok, luasnip = pcall(require, "luasnip")
if not luasnip_ok then
    return {}
end

local snippet = luasnip.snippet
local insert_node = luasnip.insert_node
local fmt = require("luasnip.extras.fmt").fmt

-- Basic React component snippets (JavaScript)
local react_js_snippets = {
    snippet("rfc", fmt([[

export function {}() {{
    return (
        <div>
            {}
        </div>
    );
}}
]], {
        insert_node(1, "ComponentName"),
        insert_node(2, "")
    })),

    snippet("useState", fmt("const [{}, set{}] = useState({});", {
        insert_node(1, "state"),
        insert_node(2, "State"),
        insert_node(3, "initialValue")
    })),

    snippet("useEffect", fmt("useEffect(() => {{\n\t{}\n}}, [{}]);", {
        insert_node(1, ""),
        insert_node(2, "")
    })),
}

-- TypeScript React component snippets
local react_ts_snippets = {
    snippet("rfc", fmt([[

type {}Props = {{
    {}
}}

export function {}({{ {} }}: {}Props) {{
    return (
        <div>
            {}
        </div>
    );
}}
]], {
        insert_node(1, "ComponentName"),
        insert_node(2, ""),
        insert_node(3, "ComponentName"),
        insert_node(4, ""),
        insert_node(5, "ComponentName"),
        insert_node(6, "")
    })),

    snippet("rfct", fmt([[
type {}Props = {{
    {}
}};

export function {}({{ {} }}: {}Props) {{
    return (
        <div>
            {}
        </div>
    );
}}

]], {
        insert_node(1, "ComponentName"),
        insert_node(2, ""),
        insert_node(3, "ComponentName"),
        insert_node(4, ""),
        insert_node(5, "ComponentName"),
        insert_node(6, "")
    })),

    snippet("useState", fmt("const [{}, set{}] = useState<{}>({});", {
        insert_node(1, "state"),
        insert_node(2, "State"),
        insert_node(3, "Type"),
        insert_node(4, "initialValue")
    })),

    snippet("useEffect", fmt("useEffect(() => {{\n\t{}\n}}, [{}]);", {
        insert_node(1, ""),
        insert_node(2, "")
    })),

    snippet("useRef", fmt("const {} = useRef<{}>({});", {
        insert_node(1, "ref"),
        insert_node(2, "Type"),
        insert_node(3, "null")
    })),

    snippet("useMemo", fmt("const {} = useMemo(() => {{\n\t{}\n}}, [{}]);", {
        insert_node(1, "memoizedValue"),
        insert_node(2, "return value;"),
        insert_node(3, "")
    })),

    snippet("useCallback", fmt("const {} = useCallback(({}) => {{\n\t{}\n}}, [{}]);", {
        insert_node(1, "callback"),
        insert_node(2, ""),
        insert_node(3, ""),
        insert_node(4, "")
    })),
}

return {
    js = react_js_snippets,
    ts = react_ts_snippets,
}

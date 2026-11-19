from dataclasses import dataclass
from pathlib import PurePath


@dataclass(frozen=True)
class Language:
    name: str
    grammar: str
    extensions: tuple[str, ...]
    functions: frozenset[str]
    branches: frozenset[str]
    loops: frozenset[str]
    boolean_operators: frozenset[str]
    parameter_lists: frozenset[str]
    has_script_body: bool = False


def language_for_path(path: str | PurePath) -> Language | None:
    return _BY_EXTENSION.get(PurePath(path).suffix.lower())


_JS_FUNCTIONS = frozenset(
    {
        "function_declaration",
        "function_expression",
        "generator_function_declaration",
        "arrow_function",
        "method_definition",
    }
)
_JS_BRANCHES = frozenset({"if_statement", "switch_case", "catch_clause", "ternary_expression"})
_JS_LOOPS = frozenset({"for_statement", "for_in_statement", "while_statement", "do_statement"})
_C_STYLE_BOOLEANS = frozenset({"&&", "||", "??"})

LANGUAGES = (
    Language(
        name="csharp",
        grammar="csharp",
        extensions=(".cs",),
        functions=frozenset(
            {
                "method_declaration",
                "constructor_declaration",
                "destructor_declaration",
                "operator_declaration",
                "conversion_operator_declaration",
                "accessor_declaration",
                "local_function_statement",
                "lambda_expression",
                "anonymous_method_expression",
            }
        ),
        branches=frozenset(
            {
                "if_statement",
                "switch_section",
                "switch_expression_arm",
                "catch_clause",
                "conditional_expression",
            }
        ),
        loops=frozenset({"for_statement", "foreach_statement", "while_statement", "do_statement"}),
        boolean_operators=_C_STYLE_BOOLEANS,
        parameter_lists=frozenset({"parameter_list"}),
    ),
    Language(
        name="typescript",
        grammar="typescript",
        extensions=(".ts", ".mts", ".cts"),
        functions=_JS_FUNCTIONS,
        branches=_JS_BRANCHES,
        loops=_JS_LOOPS,
        boolean_operators=_C_STYLE_BOOLEANS,
        parameter_lists=frozenset({"formal_parameters"}),
    ),
    Language(
        name="tsx",
        grammar="tsx",
        extensions=(".tsx",),
        functions=_JS_FUNCTIONS,
        branches=_JS_BRANCHES,
        loops=_JS_LOOPS,
        boolean_operators=_C_STYLE_BOOLEANS,
        parameter_lists=frozenset({"formal_parameters"}),
    ),
    Language(
        name="javascript",
        grammar="javascript",
        extensions=(".js", ".mjs", ".cjs", ".jsx"),
        functions=_JS_FUNCTIONS,
        branches=_JS_BRANCHES,
        loops=_JS_LOOPS,
        boolean_operators=_C_STYLE_BOOLEANS,
        parameter_lists=frozenset({"formal_parameters"}),
    ),
    Language(
        name="bash",
        grammar="bash",
        extensions=(".sh", ".bash"),
        functions=frozenset({"function_definition"}),
        branches=frozenset({"if_statement", "elif_clause", "case_item"}),
        loops=frozenset({"for_statement", "c_style_for_statement", "while_statement"}),
        boolean_operators=frozenset({"&&", "||"}),
        parameter_lists=frozenset(),
        has_script_body=True,
    ),
    Language(
        name="powershell",
        grammar="powershell",
        extensions=(".ps1", ".psm1"),
        functions=frozenset({"function_statement", "class_method_definition"}),
        branches=frozenset(
            {"if_statement", "elseif_clause", "switch_clause", "catch_clause", "trap_statement"}
        ),
        loops=frozenset({"for_statement", "foreach_statement", "while_statement", "do_statement"}),
        boolean_operators=frozenset({"-and", "-or", "-xor"}),
        parameter_lists=frozenset({"param_block", "parameter_list", "class_method_parameter_list"}),
        has_script_body=True,
    ),
    Language(
        name="lua",
        grammar="lua",
        extensions=(".lua",),
        functions=frozenset({"function_declaration", "function_definition"}),
        branches=frozenset({"if_statement", "elseif_statement"}),
        loops=frozenset({"for_statement", "while_statement", "repeat_statement"}),
        boolean_operators=frozenset({"and", "or"}),
        parameter_lists=frozenset({"parameters"}),
        has_script_body=True,
    ),
    Language(
        name="rust",
        grammar="rust",
        extensions=(".rs",),
        functions=frozenset({"function_item", "closure_expression"}),
        branches=frozenset({"if_expression", "match_arm"}),
        loops=frozenset({"for_expression", "while_expression", "loop_expression"}),
        boolean_operators=frozenset({"&&", "||"}),
        parameter_lists=frozenset({"parameters", "closure_parameters"}),
    ),
)

_BY_EXTENSION = {ext: language for language in LANGUAGES for ext in language.extensions}

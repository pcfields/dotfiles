from collections.abc import Mapping
from dataclasses import dataclass, field
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
    other_decision_operators: frozenset[str] = frozenset()
    conditionals: frozenset[str] = frozenset()
    nesting: frozenset[str] = frozenset()
    else_clauses: frozenset[str] = frozenset()
    function_bodies: frozenset[str] = frozenset()
    classes: frozenset[str] = frozenset()
    constructor_names: frozenset[str] = frozenset()
    constructors: frozenset[str] = frozenset()
    primary_constructor_owners: frozenset[str] = frozenset()
    branch_exclusions: Mapping[str, frozenset[str]] = field(default_factory=dict)
    overloads_by_type: bool = False
    condition_positions: Mapping[str, int] = field(default_factory=dict)
    parameter_exclusions: frozenset[str] = frozenset()
    receiver_names: frozenset[str] = frozenset()
    comments: frozenset[str] = frozenset({"comment"})
    has_script_body: bool = False

    @property
    def decision_operators(self) -> frozenset[str]:
        return self.boolean_operators | self.other_decision_operators


def language_for_path(path: str | PurePath) -> Language | None:
    return _BY_EXTENSION.get(PurePath(path).suffix.lower())


_JS_FUNCTIONS = frozenset(
    {
        "function_declaration",
        "function_expression",
        "generator_function_declaration",
        "generator_function",
        "arrow_function",
        "method_definition",
    }
)
_JS_BRANCHES = frozenset({"if_statement", "switch_case", "catch_clause", "ternary_expression"})
_JS_LOOPS = frozenset({"for_statement", "for_in_statement", "while_statement", "do_statement"})
_C_STYLE_BOOLEANS = frozenset({"&&", "||"})
_JS_OTHER_DECISIONS = frozenset({"??", "&&=", "||=", "??="})
_JS_NESTING = _JS_LOOPS | {"if_statement", "switch_statement", "try_statement"}
_JS_CLASSES = frozenset({"class_declaration", "class"})
_TS_CLASSES = _JS_CLASSES | {"abstract_class_declaration"}
_JS_CONDITIONALS = frozenset(
    {"if_statement", "while_statement", "do_statement", "for_statement", "ternary_expression"}
)

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
        boolean_operators=_C_STYLE_BOOLEANS | {"and", "or"},
        parameter_lists=frozenset({"parameter_list"}),
        other_decision_operators=frozenset({"??", "??="}),
        conditionals=frozenset(
            {"if_statement", "while_statement", "do_statement", "for_statement", "conditional_expression"}
        ),
        nesting=frozenset(
            {
                "if_statement",
                "for_statement",
                "foreach_statement",
                "while_statement",
                "do_statement",
                "switch_statement",
                "try_statement",
            }
        ),
        function_bodies=frozenset({"block"}),
        classes=frozenset(
            {"class_declaration", "struct_declaration", "record_declaration", "interface_declaration"}
        ),
        constructors=frozenset({"constructor_declaration"}),
        primary_constructor_owners=frozenset({"class_declaration", "struct_declaration"}),
        overloads_by_type=True,
        branch_exclusions={"switch_section": frozenset({"default"}), "switch_expression_arm": frozenset({"discard"})},
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
        other_decision_operators=_JS_OTHER_DECISIONS,
        conditionals=_JS_CONDITIONALS,
        nesting=_JS_NESTING,
        else_clauses=frozenset({"else_clause"}),
        function_bodies=frozenset({"statement_block"}),
        classes=_TS_CLASSES,
        constructor_names=frozenset({"constructor"}),
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
        other_decision_operators=_JS_OTHER_DECISIONS,
        conditionals=_JS_CONDITIONALS,
        nesting=_JS_NESTING,
        else_clauses=frozenset({"else_clause"}),
        function_bodies=frozenset({"statement_block"}),
        classes=_TS_CLASSES,
        constructor_names=frozenset({"constructor"}),
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
        other_decision_operators=_JS_OTHER_DECISIONS,
        conditionals=_JS_CONDITIONALS,
        nesting=_JS_NESTING,
        else_clauses=frozenset({"else_clause"}),
        function_bodies=frozenset({"statement_block"}),
        classes=_JS_CLASSES,
        constructor_names=frozenset({"constructor"}),
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
        name="python",
        grammar="python",
        extensions=(".py", ".pyi"),
        functions=frozenset({"function_definition", "lambda"}),
        branches=frozenset(
            {"if_statement", "elif_clause", "case_clause", "except_clause", "conditional_expression", "if_clause"}
        ),
        loops=frozenset({"for_statement", "while_statement", "for_in_clause"}),
        boolean_operators=frozenset({"and", "or"}),
        parameter_lists=frozenset({"parameters", "lambda_parameters"}),
        conditionals=frozenset({"if_statement", "elif_clause", "while_statement", "conditional_expression"}),
        condition_positions={"conditional_expression": 1},
        nesting=frozenset({"if_statement", "for_statement", "while_statement", "try_statement", "match_statement"}),
        function_bodies=frozenset({"block"}),
        classes=frozenset({"class_definition"}),
        constructor_names=frozenset({"__init__"}),
        branch_exclusions={"case_clause": frozenset({"_"})},
        parameter_exclusions=frozenset({"positional_separator", "keyword_separator"}),
        receiver_names=frozenset({"self", "cls"}),
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
        comments=frozenset({"line_comment", "block_comment"}),
    ),
)

_BY_EXTENSION = {ext: language for language in LANGUAGES for ext in language.extensions}

; Variables — catch-all placed FIRST so specific rules below override it.

(identifier) @variable

; Mojo self / Self (highlighted before the general naming-convention
; rules below so they take precedence on the literal identifiers).

((identifier) @variable.builtin
 (#eq? @variable.builtin "self"))

((identifier) @type.builtin
 (#eq? @type.builtin "Self"))

; Identifier naming conventions

((identifier) @constructor
 (#match? @constructor "^[A-Z]"))

((identifier) @constant
 (#match? @constant "^_*[A-Z][A-Z\\d_]*$"))

; Builtin functions
;
; Audited against Mojo stdlib tag mojo/v1.0.0b1 (std/prelude/__init__.mojo).
; Python-only names (exec, eval, callable, compile, vars, bool, int, float,
; list, dict, set, str, tuple, ...) dropped — Mojo's equivalents are
; capitalized types (Bool, Int, Float64, List, Dict, ...) and already match
; the @constructor rule above. Lowercase Mojo-prelude callables retained;
; idiomatic Mojo builtins (abort, debug_assert, external_call, ...) added.

((call
  function: (identifier) @function.builtin)
 (#match?
   @function.builtin
   "^(abort|abs|all|always_inline|any|ascii|atof|atol|bin|breakpoint|chr|constrained|debug_assert|divmod|enumerate|external_call|hash|hex|input|iter|len|map|materialize|max|min|next|oct|open|ord|partition|pow|print|range|rebind|rebind_var|reflect|repr|reversed|round|slice|sort|swap|unroll|zip|__mlir_attr|__mlir_op|__mlir_type)$"))

; Decorators — the "@" symbol is highlighted separately from the identifier
; so that both always receive a colour, regardless of whether the name is
; built-in, dotted, or a call expression.

((decorator
  "@" @attribute)
 (#set! priority 101))

(decorator
  (identifier) @attribute)

(decorator
  (attribute
    attribute: (identifier) @attribute))

; Built-in decorators (recognized after the generic @attribute rules above
; so their more-specific capture takes precedence on match).

((decorator
  (identifier) @attribute.builtin)
 (#match? @attribute.builtin "^(fieldwise_init|parameter|value|always_inline|noinline|staticmethod|unavailable)$"))

((decorator
  (call function: (identifier) @attribute.builtin))
 (#match? @attribute.builtin "^(fieldwise_init|parameter|value|always_inline|noinline|staticmethod|unavailable)$"))

; Function calls

(call
  function: (attribute attribute: (identifier) @function.method))
(call
  function: (identifier) @function)

; Function definitions

(function_definition
  name: (identifier) @function)

(attribute attribute: (identifier) @property)
(type (identifier) @type)

; Literals

[
  (none)
  (true)
  (false)
] @constant.builtin

[
  (integer)
  (float)
] @number

(comment) @comment
(string) @string
(escape_sequence) @escape

; Docstrings — first expression of a function body that is a string.
; Disabled: tree-sitter reports this pattern as impossible in the current
; grammar (the path through `_statement` → `_simple_statements` → inlined
; `_simple_statement` → `expression_statement` → `string` requires wildcard
; matching that the query compiler rejects as impossible).
; (function_definition
;   body: (block (expression_statement (string) @string.doc)))

(interpolation
  "{" @punctuation.special
  "}" @punctuation.special) @embedded

; Punctuation brackets.
; `{`/`}` excluded — tree-sitter's query optimizer rejects bare matching
; of these tokens because they only appear inside compound nodes
; (dictionary, set, struct_literal, result_convention, etc.).

[
  "("
  ")"
  "["
  "]"
] @punctuation.bracket

; Operators

[
  "-"
  "-="
  "!="
  "*"
  "**"
  "**="
  "*="
  "/"
  "//"
  "//="
  "/="
  "&"
  "%"
  "%="
  "^"
  "+"
  "->"
  "+="
  "<"
  "<<"
  "<="
  "<>"
  "="
  ":="
  "=="
  ">"
  ">="
  ">>"
  "|"
  "~"
  "and"
  "in"
  "is"
  "not"
  "or"
  "is not"
  "not in"
] @operator

; General keywords (Python-compatible)

[
  "as"
  "assert"
  "async"
  "await"
  "break"
  "class"
  "continue"
  "def"
  "del"
  "elif"
  "else"
  "except"
  "exec"
  "finally"
  "for"
  "from"
  "global"
  "if"
  "import"
  "lambda"
  "nonlocal"
  "pass"
  "print"
  "raise"
  "return"
  "try"
  "while"
  "with"
  "yield"
  "match"
  "case"
] @keyword

; Mojo-specific declaration and effect keywords

[
  "struct"
  "trait"
  "type"
  "var"
  "comptime"
  "raises"
  "capturing"
  "escaping"
  "thin"

  "abi"
  "where"
  "owned"
  "unified"
  "inferred"
] @keyword

; `fn` is a hard compilation error in Mojo v1.0.0b2 — keep parsing for
; legacy code but mark it as an error in highlighting.

[
  "fn"
] @keyword.error

; `where` in type parameter lists is deprecated in Mojo v1.0.0b2.
; Use a trailing `where` clause on the declaration instead.

(type_parameter
  (where_clause
    "where" @keyword.deprecated)
  (#set! priority 105))

[
  "borrowed"
  "inout"
  "mut"
  "read"
  "ref"
  "out"
  "deinit"
] @keyword.modifier

; Capture list punctuation — `[` and `]` inside `fn() capturing[...]`.

(capture_list
  "[" @punctuation.bracket
  "]" @punctuation.bracket)

; MLIR interop — __mlir_type, __mlir_op and __mlir_attr backtick fragments.

(mlir_type "." @punctuation.special (#set! "priority" 110))
(mlir_type "," @punctuation (#set! "priority" 110))
(mlir_type) @type

(mlir_fragment (type) @type (#set! "priority" 110))
(mlir_fragment (integer) @number (#set! "priority" 110))
(mlir_fragment (mlir_punctuation) @operator (#set! "priority" 110))

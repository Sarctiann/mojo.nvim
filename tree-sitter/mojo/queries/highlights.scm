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
 (#match? @constant "^[A-Z][A-Z_]*$"))

; Builtin functions

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
    "^(abort|abs|all|any|ascii|atof|atol|bin|breakpoint|chr|constrained|debug_assert|divmod|enumerate|external_call|hash|hex|input|iter|len|map|materialize|max|min|next|oct|open|ord|partition|pow|print|range|rebind|rebind_var|reflect|repr|reversed|round|slice|sort|swap|zip)$"))

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

(decorator
  (call
    (identifier) @attribute))

(decorator
  (call
    (attribute
      attribute: (identifier) @attribute)))

; Built-in decorators (recognized after the generic @attribute rules above
; so their more-specific capture takes precedence on match).

((decorator
  (identifier) @attribute.builtin)
 (#match? @attribute.builtin "^(fieldwise_init|parameter|value|always_inline|noinline|staticmethod)$"))

((decorator
  (call function: (identifier) @attribute.builtin))
 (#match? @attribute.builtin "^(fieldwise_init|parameter|value|always_inline|noinline|staticmethod)$"))

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

(interpolation
  "{" @punctuation.special
  "}" @punctuation.special) @embedded

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
] @operator

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

; Mojo-specific declaration keywords. The grammar accepts each as an
; anonymous string token (see grammar.js: `fn` in function_definition,
; `raises` in raises_clause, etc.), so literal-token highlighting fires.

[
  "fn"
  "var"
  "struct"
  "trait"
  "alias"
  "comptime"
] @keyword

(raises_clause) @keyword

"raises" @keyword

; Mojo 1.0 function effects — appear in function signatures after parameters.

[
  "thin"
  "register_passable"
] @keyword

; Mojo argument-convention keywords. Appear only inside `mojo_parameter`
; (see grammar.js: argument_convention). Captured as @keyword.modifier so
; themes can color them distinctly from control-flow keywords.

[
  "borrowed"
  "inout"
  "mut"
  "read"
  "ref"
  "out"
  "deinit"
] @keyword.modifier

; Capture list punctuation — `{` and `}` in capture context is syntactically
; distinct from dictionary/block braces.

(capture_list
  "{" @punctuation.bracket
  "}" @punctuation.bracket)

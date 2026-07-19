; ---------------------------------------------------------------------------- 
; Comments
(comment) @comment @spell

(
  (module . (comment) @keyword.directive @nospell)
  (#lua-match? @keyword.directive "^#!/")
)

; ---------------------------------------------------------------------------- 
; Symbols
[
  (line_continuation)
  (keyword_only_marker)
  (positional_only_marker)
  (infer_only_marker)
  (ellipsis)
  "`"
  (import_prefix)
  (mlir_attr_special_character)
  (mlir_type_special_character)
] @punctuation.special

[
  (underscore)
  (wildcard_import)
  (mlir_attr_prefix)
  (mlir_type_prefix)
] @character.special

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  ","
  "."
  ":"
  ";"
] @punctuation.delimiter

; ---------------------------------------------------------------------------- 
; Operators
[
  "-"
  "-="
  "->"
  ":="
  "!="
  "@"
  "@="
  "*"
  "**"
  "**="
  "*="
  "/"
  "//"
  "//="
  "/="
  "&"
  "&="
  "%"
  "%="
  "^"
  "^="
  "+"
  "+="
  "<"
  "<<"
  "<<="
  "<="
  "="
  "=="
  ">"
  ">="
  ">>"
  ">>="
  "|"
  "|="
  "~"
  (mlir_operator)
] @operator

; ---------------------------------------------------------------------------- 
; Keywords
[
  "and"
  "del"
  "in"
  "is not"
  "is"
  "not in"
  "not"
  "or"
] @keyword.operator

[
  "def"
  "lambda"
] @keyword.function

(mlir_region_signature "__mlir_region" @keyword.function)

[
  "as"
  "assert"
  "from"
  "global"
  "nonlocal"
  "pass"
  "with"
  "comptime"
  "ref"
  "var"
  (thin)
] @keyword

(abi "abi" @keyword)
(where_clause "where" @keyword)

(callable_parameters
  [
    "deinit"
    "mut"
    "out"
    "read"
    "ref"
    "var"
  ] @keyword.modifier)

(function_type_parameters
  [
    "deinit"
    "mut"
    "out"
    "read"
    "ref"
    "var"
  ] @keyword.modifier)

(capture_parameter
  [
    "mut"
    "read"
    "ref"
    "var"
  ] @keyword.modifier)

[
  "class"
  "struct"
  "trait"
] @keyword.type

(extension_header "__extension" @keyword.type)

[
  "async"
  "await"
] @keyword.coroutine

[
  "return"
  "yield"
] @keyword.return

(yield "from" @keyword.return)

[
  "elif"
  "else"
  "if"
] @keyword.conditional

(match_statement "match" @keyword.conditional)
(case_clause "case" @keyword.conditional)

[
  "break"
  "continue"
  "for"
  "while"
] @keyword.repeat

[
  "except"
  "finally"
  "raise"
  "try"
] @keyword.exception

(raises "raises" @keyword.exception)
(raise_statement "from" @keyword.exception)

(try_statement (else_clause "else" @keyword.exception))

"import" @keyword.import
(aliased_import "as" @keyword.import)
(relative_aliased_import "as" @keyword.import)
(selective_import_statement "from" @keyword.import)

; ---------------------------------------------------------------------------- 
; Literals
[
  (true)
  (false)
] @boolean

; ---------------------------------------------------------------------------- 
; Numeric literals
(integer) @number
(float) @number.float

; ---------------------------------------------------------------------------- 
; Strings
(mlir_string) @string.special
(string) @string
(abi (string) @string.special)

[
  (escape_sequence)
  (escape_interpolation)
] @string.escape

; Reset highlighting in f-string interpolations
(interpolation) @none @nospell

(interpolation[
  "{"
  "}"
] @punctuation.special)

(format_expression[
  "{"
  "}"
] @punctuation.special)

; ---------------------------------------------------------------------------- 
; Docstrings
(module _* (string (string_content) @spell)+ @string.documentation)
(block _* (string (string_content) @spell)+ @string.documentation)

; ---------------------------------------------------------------------------- 
; Variables
(identifier) @variable
(escaped_identifier (escaped_identifier_content) @variable)

; ---------------------------------------------------------------------------- 
; Subscripts
(
  (member_subscript
    value: (identifier) @variable.member)
  (#lua-match? @variable.member "^[a-z0-9_].*$")
)

([
  (member_subscript
    value: (identifier) @type)
  (subscript
    value: (identifier) @type)
](#lua-match? @type "^_*[A-Z][A-Za-z0-9_]*$"))

; ---------------------------------------------------------------------------- 
; Member accesses
(
  (member_access
    member: (identifier) @variable.member)
(#lua-match? @variable.member "^[a-z0-9_].*$"))

([
  (member_access
    value: (identifier) @type)
  (member_access
    member: (identifier) @type)
](#lua-match? @type "^_*[A-Z][A-Za-z0-9_]*$"))

(
  (member_access
    value: (identifier) @variable.builtin)
  (#eq? @variable.builtin "self")
)

; ---------------------------------------------------------------------------- 
; Function calls
(call
  function: [
    (identifier) @function.call
    (subscript
      value: (identifier) @function.call)
  ])

(member_call
  function: [
    (identifier) @function.method.call
    (member_subscript
      value: (identifier) @function.method.call)
  ])

([
  (call
    function: [
      (identifier) @constructor
      (subscript
        value: (identifier) @constructor)
    ])
  (member_call
    function: [
      (identifier) @constructor
      (member_subscript
        value: (identifier) @constructor)
    ])
](#lua-match? @constructor "^_*[A-Z]"))

; ---------------------------------------------------------------------------- 
; Built-in functions
(
  (call
    function: (identifier) @function.builtin)
  (#any-of? @function.builtin
    "conforms_to"
    "debug_assert"
    "origin_of"
    "print"
    "type_of")
)

(
  (call
    function: (subscript
      value: (identifier) @function.builtin))
  (#any-of? @function.builtin
    "bit_width_of"
    "debug_assert")
)

; ---------------------------------------------------------------------------- 
; Parameters
(parameter_member (member_access
  value: [
    (identifier) @variable.parameter
    (subscript
      value: (identifier) @variable.parameter)
  ]))
(generic_parameter
  value: (identifier) @variable.parameter)
(parameter (identifier) @variable.parameter)
(named_parameter
  name: (identifier) @variable.parameter)

([
  (parameter_member (member_access
    value: [
      (identifier) @type
      (subscript
        value: (identifier) @type)
    ]))
  (generic_parameter
    value: (identifier) @type)
  (parameter (identifier) @type)
  (named_parameter
    name: (identifier) @type)
](#lua-match? @type "^_*[A-Z][A-Za-z0-9_]*$"))

; ---------------------------------------------------------------------------- 
; MLIR
(mlir_op (mlir_dotted_identifier (identifier) @variable.member))
(mlir_op (mlir_dotted_identifier (identifier) @function.call .))
(mlir_parameter (mlir_dotted_identifier (identifier) @variable.member))
(mlir_type (identifier) @variable.member)
(mlir_attr (identifier) @variable.member)

(mlir_op . "__mlir_op" @type.builtin)

(mlir_type . [
  "__mlir_type"
  "__mlir_deferred_type"
] @type.builtin)

(mlir_attr . [
  "__mlir_attr"
  "__mlir_deferred_attr"
] @type.builtin)

(
  (mlir_dotted_identifier . (identifier) @type.builtin)
  (#any-of? @type.builtin
    "co"
    "hlcf"
    "index"
    "kgen"
    "lit"
    "llvm"
    "nvvm"
    "pop")
)

; ---------------------------------------------------------------------------- 
; Callable parameters
(keyword_argument
  name: (identifier) @variable.parameter)
(constrained_mlir_parameter_decl
  name: (identifier) @variable.parameter)
(variadic_parameter_decl
  name: (identifier) @variable.parameter)
(parameter_decl
  name: (identifier) @variable.parameter)
(lambda_default_parameter_decl
  name: (identifier) @variable.parameter)
(constrained_variadic_parameter_decl
  name: (identifier) @variable.parameter)
(constrained_parameter_decl
  name: (identifier) @variable.parameter)
(default_parameter_decl
  name: (identifier) @variable.parameter)

([
  (callable_parameter/parameter_decl
    name: (identifier) @variable.builtin)
  (callable_parameter/constrained_parameter_decl
    name: (identifier) @variable.builtin)
](#eq? @variable.builtin "self"))

; ---------------------------------------------------------------------------- 
; Capture parameters
(capture_parameter
  name: (identifier) @variable)

; ---------------------------------------------------------------------------- 
; Parameter declarations
([
  (parameter_declaration/variadic_parameter_decl
    name: (identifier) @type.definition)
  (parameter_declaration/parameter_decl
    name: (identifier) @type.definition)
  (parameter_declaration/constrained_variadic_parameter_decl
    name: (identifier) @type.definition)
  (parameter_declaration/constrained_parameter_decl
    name: (identifier) @type.definition)
  (parameter_declaration/default_parameter_decl
    name: (identifier) @type.definition)
  (parameter_declaration/default_parameter_decl (constrained_parameter_decl
    name: (identifier) @type.definition))
  (comptime_parameter
    name: (identifier) @type.definition)
](#lua-match? @type.definition "^_*[A-Z][A-Za-z0-9_]*$"))

; ---------------------------------------------------------------------------- 
; Decorators
(decorator "@" @attribute[
  (identifier) @attribute
  (member_access
    member: [
      (identifier) @attribute
      (member_call
        function: (identifier) @attribute)
    ] .)
  (member_call
    function: (identifier) @attribute)
  (call
    function: (identifier) @attribute)
])

(
  (decorator (identifier) @attribute.builtin)
  (#any-of? @attribute.builtin
    "always_inline"
    "doc_hidden"
    "export"
    "fieldwise_init"
    "implicit"
    "no_inline"
    "staticmethod")
)

(
  (decorator (call
    function: (identifier) @attribute.builtin))
  (#any-of? @attribute.builtin
    "align"
    "always_inline"
    "deprecated"
    "explicit_destroy"
    "export")
)

(
  (decorator (member_access
    value: (identifier) @attribute.builtin @_first
    . member: (member_call
      function: (identifier) @attribute.builtin @_second)))
  (#eq? @_first "compiler")
  (#eq? @_second "register")
)

; ---------------------------------------------------------------------------- 
; Function declarations
(function_signature name: (identifier) @function)
(type_conversion) @function.macro

; ---------------------------------------------------------------------------- 
; Trait declarations
(trait_header name: (identifier) @type.definition)

(trait_declaration
  body: (block[
    (function_declaration (function_signature
      name: (identifier) @function.method))
    (decorated_declaration
      declaration: (function_declaration
        (function_signature
          name: (identifier) @function.method)))
  ]))

; ---------------------------------------------------------------------------- 
; Extension declarations
(extension_header name: (identifier) @type)

(extension_declaration
  body: (block[
    (function_declaration (function_signature
      name: (identifier) @function.method))
    (decorated_declaration
      declaration: (function_declaration
        (function_signature
          name: (identifier) @function.method)))
  ]))

; ---------------------------------------------------------------------------- 
; Struct declarations
(struct_header name: (identifier) @type.definition)

(
  (struct_declaration
    body: (block[
      (assignment
        left: (constrained_lhs (identifier) @variable.member))
      (decorated_declaration
        declaration: (assignment
          left: (constrained_lhs (identifier) @variable.member)))
    ]))
  (#lua-match? @variable.member "^[a-z0-9_].*$")
)

(struct_declaration
  body: (block[
    (function_declaration (function_signature
      name: (identifier) @function.method))
    (decorated_declaration
      declaration: (function_declaration
        (function_signature
          name: (identifier) @function.method)))
  ]))

(
  (struct_declaration
    body: (block[
      (function_declaration (function_signature
        name: (identifier) @constructor))
      (decorated_declaration
        declaration: (function_declaration
          (function_signature
            name: (identifier) @constructor)))
    ]))
  (#eq? @constructor "__init__")
)

; ---------------------------------------------------------------------------- 
; MLIR region declarations
(mlir_region_signature name: (identifier) @function)

; ---------------------------------------------------------------------------- 
; Imports
(selective_import_statement
  module: [
    (import
      name: (dotted_identifier (identifier) @module))
    (relative_import
      name: (dotted_identifier (identifier) @module))
  ])

(
  (selective_import_statement "import" [
    (import
      name: (dotted_identifier (identifier) @type))
    (aliased_import
      name: (dotted_identifier (identifier) @type))
    (aliased_import
      alias: (identifier) @type)
  ])
  (#lua-match? @type "^_*[A-Z][A-Za-z0-9_]*$")
)

(module_import_statement
  module: [
    (import
      name: (dotted_identifier (identifier) @module))
    (aliased_import
      name: (dotted_identifier (identifier) @module)
      alias: (identifier) @module)
    (relative_import
      name: (dotted_identifier (identifier) @module))
    (relative_aliased_import
      name: ((dotted_identifier (identifier) @module))?
      alias: (identifier) @module)
  ])

; ---------------------------------------------------------------------------- 
; Constants
((identifier) @constant (#lua-match? @constant "^_*[A-Z]{2}[A-Z0-9_]*$"))
(none) @constant.builtin

; ---------------------------------------------------------------------------- 
; Built-in types
(self) @type.builtin

(
  (member_access
    value: (subscript
      value: (identifier) @type.builtin))
  (#eq? @type.builtin "reflect")
)

([
  (generic_parameter
    value: (identifier) @type.builtin)
  (subscript
    value: (identifier) @type.builtin)
](#any-of? @type.builtin
  "SIMD"
  "Reflected"))

(
  (selective_import_statement "import" [
    (import
      name: (dotted_identifier (identifier) @type.builtin))
    (aliased_import
      name: (dotted_identifier (identifier) @type.builtin))
  ])
  (#any-of? @type.builtin
    "SIMD"
    "Reflected")
)

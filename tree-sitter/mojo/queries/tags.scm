(module (expression_statement (assignment left: (identifier) @name) @definition.constant))

(struct_header
  name: (identifier) @name) @definition.class

(function_signature
  name: (identifier) @name) @definition.function

(call
  function: (identifier) @name
) @reference.call

(member_call
  function: (identifier) @name
) @reference.call

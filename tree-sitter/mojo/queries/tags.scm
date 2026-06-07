(class_definition
  name: (identifier) @name) @definition.class

(struct_definition
  name: (identifier) @name) @definition.class

(trait_definition
  name: (identifier) @name) @definition.interface

(function_definition
  name: (identifier) @name) @definition.function

(alias_declaration
  name: (identifier) @name) @definition.constant

(variable_declaration
  name: (identifier) @name) @definition.variable

(call
  function: [
      (identifier) @name
      (attribute
        attribute: (identifier) @name)
  ]) @reference.call

# Test file for mojo.nvim highlights.scm (dmitry-salin/tree-sitter-mojo)
# Exercises highlight groups against current Mojo (nightly language reference).

# --- 0. Basic literals ---

var yes = True                             # (true) @boolean
var no = False                             # (false) @boolean
var nothing = None                         # (none) @constant.builtin
var count = 42                             # (integer) @number
var big = 1_000_000                        # (integer) @number
var ratio = 3.14                           # (float) @number.float
var greeting = "hello"                     # (string) @string
var name = "world"                         # (string) @string
var location = "src/main.mojo"             # (string) @string

# --- 1. Function effects (raises / thin / abi) ---

def func_raises() raises:                  # "raises" @keyword.exception
    pass

def func_typed_raises() raises Error:      # "raises" @keyword.exception, Error @type
    pass

def func_thin() thin:                      # "thin" @keyword
    pass

@parameter
def func_abi() abi("C"):                   # "abi" @keyword
    pass

# --- 2. Declarations: struct / trait / type alias / var ---

@fieldwise_init
struct MyStruct(Copyable, Movable):
    var x: Int
    var y: Int

    def get_x(self) -> Int:
        return self.x

trait Greetable:
    def greet(self) -> String:
        ...

type MyAlias = Int                         # "type" @keyword.type
var my_var: Int = 42                       # "var" @keyword

# --- 3. Argument conventions (@keyword.modifier) ---

def read_param(mut buf: Tensor, read other: Tensor):
    pass

def out_param(out result: Int):
    pass

def ref_param(ref[origin] item: Tensor):
    pass

# --- 4. MLIR interop ---

def mlir_example():
    var t = __mlir_type.index              # "index" in mlir_type @type

# --- 5. Punctuation brackets ---

var lst = [1, 2, (3 + 4)]                  # ()[]{} should be @punctuation.bracket

# --- 6. Builtins ---

var length = len(items)                    # call
print(greeting)                            # "print" @function.builtin
debug_assert(count > 0)                    # "debug_assert" @function.builtin

# --- 7. Constants with leading/all uppercase ---

var MAX_SIZE = 1024                        # @constant
var DEFAULT_NAME = "anon"                  # @constant

# --- 8. Docstring ---

def documented():
    """This is a docstring."""             # @string.documentation
    pass

# --- 9. Intersection & callable types ---

type MyBound = Copyable & Movable          # "&" @operator
type CallableType = def(Int) -> Int        # callable type literal

# --- 10. comptime control flow ---

comptime if True:                          # "comptime" @keyword
    print("compile time")

comptime for i in range(5):                # "comptime" @keyword
    pass

# --- 11. Transfer expression ---

def transfer_example():
    var owned_value = compute()
    return owned_value^                    # postfix ^ operator

# --- 12. Extension definition ---

__extension List:
    pass

# --- 13. Typed self (Self) and constructor ---

struct Buffer:
    def __init__(out self):                 # "__init__" @constructor
        pass

    def clone(self: Self) -> Self:
        return self

# --- 14. Calls & member access ---

var s = MyStruct(1, 2)                      # constructor call
var gx = s.get_x()                          # member call
print(s.x)                                  # member access

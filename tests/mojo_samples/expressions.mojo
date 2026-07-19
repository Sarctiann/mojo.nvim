# Expressions — operators, comparisons, comprehensions

# Arithmetic
var a = 1 + 2
var b = 3 - 4
var c = 5 * 6
var d = 7 / 8
var e = 9 // 10
var f = 11 % 12
var g = 13 ** 14

# Augmented assignments
a += 1
b -= 2
c *= 3
d /= 4
e //= 5
f %= 6
g **= 7

# Bitwise
var h = 1 & 2
var i = 3 | 4
var j = 5 ^ 6
var k = ~7
var l = 8 << 1
var m = 9 >> 2

# Comparisons
var eq = 1 == 2
var ne = 3 != 4
var lt = 5 < 6
var gt = 7 > 8
var le = 9 <= 10
var ge = 11 >= 12

# Boolean
var and_ = True and False
var or_ = True or False
var not_ = not True

# Identity/membership
var is_ = x is y
var is_not = x is not y
var in_ = x in y
var not_in = x not in y

# Arrow (return type)
def example() -> Int:
    return 0

# Walrus operator
if (n := len(items)) > 0:
    print(n)

# Slice
var sl = items[1:3]
var sl2 = items[:5]
var sl3 = items[2:]

# F-string interpolation
var name = "world"
var msg = f"hello {name}"

# List/dict/set literals
var lst = [1, 2, 3]
var dct = {"a": 1, "b": 2}
var st = {1, 2, 3}

# Comprehensions
var squares = [x * x for x in range(10)]
var evens = {x for x in range(10) if x % 2 == 0}
var pairs = {x: x * 2 for x in range(5)}

# Generator expression
var gen_expr = (x * 2 for x in items)

# Ternary / conditional expression
var val = a if cond else b

# Negative numbers / unary
var neg = -42
var pos = +7
var inv = ~x

# Type conversion
var ptr = DTypePointer[DType.ui8]
var as_int = int(3.14)

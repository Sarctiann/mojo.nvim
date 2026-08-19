# Keywords — every keyword token in the grammar

# Control flow
if True:
    pass
elif False:
    pass
else:
    pass

for x in range(10):
    break
    continue

while True:
    pass

match x:
    case 1:
        pass
    case _:
        pass

# Functions
def f():
    return 42

def g() -> Int:
    return 0

# Try/except
try:
    raise Error("fail")
except Error as e:
    pass
finally:
    pass

# With
with open("f"):
    pass

# Async
async def h():
    await task

# Imports
import os
from sys import path
from . import local_module
from .utils import helper

# Declarations
var x: Int = 1
type T = Int
struct S:
    pass
trait T:
    pass

# Mojo-specific (only valid in their grammatical context)
def abi_example() abi("C"):
    pass

# Lambda (Mojo 1.0: parenthesized typed args + optional capture list)
var f = lambda (x: Int) -> Int: x + 1
var g = lambda (x: Int) {} -> Int: x + 1

# Del
del x

# Exec (legacy Python compat)
exec("code")

# Pass
pass

# Assert
assert True

# Yield
def gen():
    yield 1
    yield from items

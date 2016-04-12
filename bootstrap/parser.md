
# Parser

  Hazelnut is a lisp!

  1. Types
  2. How to Parse
  3. Operators

## Types

Type of a reader macro:

    A function that takes a stream of characters, the readtable, and returns a Token

Type of an AST:

  a node in an AST can be one of three types:
    
    Token

      - Number
      - Identifyier (Symbol)
      - String 

    List

      - Contains a list of expressions

    Block

      - Psych! It's just a list that looks like this `block arguments (... list of expressions ...)`

The readtable:

  The readtable is a mapping of characters to reader macros!

## How to Parse

The parser will work through reader macros.
There will be a global table that lists reader macros.

I will build two things into the compiler that aren't defined as reader macros:
  * Parsing identifiers.
      (Read characters until one of the characters that you hit is a reader macro)
  * Parsing numbers
      (Read an int or a float until one of the characters is a reader macro)

Reader macros I have thought through:

  * Space: This is a reader macro that returns 'nil' - Nil is not a valid ast so it is ignored.
  * Open parenthesis: This reader macro calls 'read' until 'read' returns a close parenthesis.
  * Close parenthesis: A reader macro that returns a close parenthesis.
  * Open curly brace: Calls 'read' until a newline or a ':' is returned. These are the arguments.
                      Then calls read until a '}' is returned. These are the expressions in the block.
                      Returns a block.
  * Close curly brace: A reader macro that returns a close curly brace.

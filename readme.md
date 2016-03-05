
## Almond

Hi! Almond is a programming language I'm working on.
It's pretty simple, with the main goal being to bootstrap
itself as quickly as possible. It compiles to Go.

# Syntax

## Haskell-like function calls

```ruby
assert (equals this that)
```

There are no operators, for simplicity.

## Blocks

Inspired by the ruby blocks:
```
map (list 3 4 5) { x: x * x }
```

Fun fact: the `:` here is an alias for a newline or semicolon. This is also valid:

```
map (list 3 4 5) do x
  x * x
end
```

You've probably gotten by now that Almond dynamically typed (and still compiles to Go), 
Almond by default returns the last line in a block.

## That's it!

That's all the syntax there is. It's not quite as simple as lisp, but the AST is very simple:
each node has a name, a list of nodes and a block, which has a list of identifiers and a list of nodes.
```
       Node
      / | \
     /  |  \
    /   |   \
Name Arguments Block
 |       |       |   \
 |       |       |    \
Ident  [Node]  [Node] [Ident]
```
* By "Ident", I mean a literal word in the text, like "if" or "return" or "fish".

My hope is that this will make macros easy, although I haven't gone about implementing them yet.

# Progress

* [ ] Finish the first compiler
  - [x] Parse the tokens
  - [x] Parse the ast
  - [x] Generate function calls
  - [x] Generate `if` and `else` statements
  - [x] Generate `let` statements
  - [x] Differentiate between vars and function calls
  - [x] Generate function definitions
  - [ ] Command line tool
  - [ ] Constants
  - [ ] Generate structs
  - [ ] Make a decent stdlib in Go
* [ ] Bootstrap
* [ ] Add objects and methods
* [ ] Add macros w/ interpreter!

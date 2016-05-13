
# [depricated]

Working on [acorn](https://github.com/Charlesetc/acorn) instead. Similar language, compiles to llvm and writen in rust.

## Hazelnut

![hazelnut logo](http://www.charlesetc.com/hazelnut/logo/hazelnut.svg)

Hi! Hazelnut is a programming language I'm working on.
It's pretty simple, with the main goal being to bootstrap
itself as quickly as possible. It compiles to Go.

# Syntax

## Haskell-like function calls

```ruby
assert (= this that)
```

## Operators

Postfix or prefix

```ruby
2 + 3 * 8
```

```ruby
(+ 2 (* 3 8))
```

## Blocks

Inspired by the ruby blocks:
```ruby
[3 4 5].map { x: x * x }
```

Fun fact: the `:` here is an alias for a newline or semicolon. This is also valid:

```ruby
[3 4 5].map do x
  x * x
end
```

You've probably gotten by now that Hazelnut is dynamically typed (and still compiles to Go), Hazelnut by default returns the last line in a block.

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

# Features

## Functions

```ruby
define add_2 { x: x + 2 }

add_2 5   # => 7
```

## Structures
```ruby
struct Animal {
  color
  height
}

a = new animal
a.color = "red"
a.color   # => "red"
```

## Control Flow

```ruby
if is_red? panda {
  puts "This is a red panda!"
} else {
  puts "This is not a red panda!"
}
```

There aren't for loops yet but that's just because I haven't gotten to them.

# Progress

* [ ] Finish the first compiler
  - [x] Parse the tokens
  - [x] Parse the ast
  - [x] Generate function calls
  - [x] Generate `if` and `else` statements
  - [x] Generate `let` statements
  - [x] Differentiate between vars and function calls
  - [x] Generate function definitions
  - [x] Command line tool
  - [x] Constants
      * [x] Integers
      * [x] Booleans
      * [x] Floats
      * [x] Strings
      * [x] Structs
  - [x] Bindings to Go code
  - [x] Use a different namespace for Hazelnut functions
  - [x] Operators with shunting yard
  - [x] Support dot syntax
  - [x] Methods on structs
  - [ ] Make namespaces and 'include' for hazelnut
  - [ ] Better error messages
  - [ ] Support for panic and defer
* [ ] Make a decent standard library
  - [ ] IO - gets puts write to file.
  - [ ] String manipulation
  - [ ] Testing w/ assertions
  - [ ] Generic pipes.
* [ ] Bootstrap
* [ ] Add macros w/ interpreter!

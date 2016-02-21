
## Almond


Every expression looks like this:
```ruby

some_function_or_macro argument (function argument) do
  call_some function
end

or

some_function_or_marco argument (function other_argument)

(list 2 3 4 5 6).map x do
  plus 2 3
end

(range 2 6).map x do
  puts (plus 2 x)
end
```

# What's the point?

Easy, consistent syntax -- macros are doable.
Easy to parse and therefore bootstrap

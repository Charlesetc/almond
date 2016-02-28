
## Almond


Every expression looks like this:
```ruby

some_function_or_macro argument (function argument) do
  call_some function
end

or

some_function_or_marco argument (function other_argument)

class Iterator do

  define map do xs function
    let x (head xs) xs (tail xs) do
      if (empty? x)
        (list)
        (cons (map xs function) (function x))
    end
  end

end


(list 2 3 4 5 6).map do x
  plus 2 3
end

(range 2 6).map x do
  puts (plus 2 x)
end
```

# What's the point?

Easy, consistent syntax -- macros are doable.
Easy to parse and therefore bootstrap

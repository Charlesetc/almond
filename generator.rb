# generator.rb

require_relative './data.rb'
require_relative './generator/call_tree.rb'
require 'pry'

class Generator

  include Tree

  attr_accessor :if_statement

  def initialize(forest)
    @forest = forest
    @functions = []
    @bindings = []
  end

  def generate
    ingest_forest
    output = [
      generate_headers,
      generate_functions,
      generate_main,
    ].join
    File.write("/tmp/hazelnut", output)
    `goimports -w /tmp/hazelnut`
    `gofmt -s /tmp/hazelnut`.gsub "\t", "  "
  end

  def ingest_forest
    @forest.reject! do |tree|
      if tree.symbol == :define
        @functions << tree
      elsif tree.symbol == :binding
        @bindings << tree
      end
    end
  end

  def function_start(symbol, args, is_closure)
      [
        "func ",
        symbol,
        "(arguments []*any",
        is_closure ? "" : ", block func([]*any) *any",
        ") *any {
        if len(arguments) != #{args.length} {
          panic(\"Wrong number of arguments for #{symbol} - not #{args.length}\")
        }\n"
      ].join
  end

  def function_end()
    "}"
  end

  def generate_function(symbol, args, forest, is_closure = false)

      defined_arguments = args.each_with_index.map do |a, i|
        raise "arguments to a function definition must be idents" unless a.is_a?(Token) or a.is_ident?
        stack_push a
        "#{a.symbol} := arguments[#{i}];"
      end

      start = function_start(symbol, args, is_closure)

      [
        start,
        defined_arguments,
        generate_calls(forest),
        function_end,
        is_closure ? "" : "\n\n",
      ].join
  end

  def generate_functions
    @functions.map do |tree|
      function_name = tree.arguments.shift
      unless function_name and function_name.is_ident?
        raise "first argument to define must be an ident"
      end
      raise "define takes a block" unless tree.block
      raise "define's block doesn't take any arguments" if tree.block.arguments and not tree.block.arguments.empty?
      enter_stack
      output = generate_function(function_name.symbol, tree.arguments, tree.block.forest) 
      exit_stack
      output
    end.join("\n") + @bindings.map { |tree| generate_binding tree }.join("\n")
  end

  def generate_binding(tree)
    raise "binding takes two arguments" unless tree.arguments.length == 2
    raise "binding takes a block" unless tree.block
    unless tree.block.arguments.length.even?
      raise "binding's block takes an even number of arguments"
    end
    unless (tree.block.forest.length == 2 and
            tree.block.forest[0].is_string? and
            tree.block.forest[1].is_string?)
      raise "binding's block takes exactly two strings"
    end
    fn_name = tree.arguments[0].symbol
    fn_type = tree.arguments[1].symbol
    arg_names = tree.block.arguments.each_slice(2).map { |a, b| a }
    start = function_start(fn_name, arg_names, false)

    type_arguments = tree.block.arguments.each_slice(2).with_index.map { |args, i|
      name, type = args
      "
      if arguments[#{i}].hazelnut_type != #{TYPE_MAPPING[type.symbol]} {
         panic(\"#{i}th argument of #{fn_name} takes a #{type.symbol}\")
       }
       #{name.symbol} := (*#{type.symbol})(arguments[#{i}].hazelnut_data)
      "
    }
    preceeding, return_value = tree.block.forest

    return_value = "
      return into_any(#{TYPE_MAPPING[fn_type]}, unsafe.Pointer(#{unescape(return_value)}))
    "

    [
      start,
      type_arguments,
      unescape(preceeding),
      return_value,
      function_end,
    ].join
  end

  def generate_headers
    "package main\n"
  end

  def generate_main
    [
      "
      func main() {
      ",
      generate_calls(@forest, false),
      "
      }
      ",
    ].join
  end

  def generate_calls(forest, includereturn = true)
    forest.map! { |tree| fn = call(tree) }

    if includereturn
      ret = forest[-1]
     # Not sure if this is necessary
      if ret.return_value != ret.body
        ret.prerequisites += ret.body
        ret.body = ret.return_value
      end
      ret.body = "return " + ret.body
    end
    forest.map! { |fn| [fn.prerequisites, fn.body] }.join(';')
  end

end

def unescape(expression)
  code = expression.symbol.to_s[1..-2]
  code.gsub "\\\\", "\\"
  code.gsub "\\\"", "\""
end

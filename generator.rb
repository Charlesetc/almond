# generator.rb

require_relative './data.rb'
require_relative './generator/call_tree.rb'

class Generator

  include Tree

  attr_accessor :if_statement

  def initialize(forest)
    @forest = forest
    @functions = []
  end

  def generate
    ingest_forest
    output = [
      generate_headers,
      generate_functions,
      generate_main,
    ].join
    File.write("/tmp/almond", output)
    `goimports -w /tmp/almond`
    `gofmt -s /tmp/almond`.gsub "\t", "  "
  end

  def ingest_forest
    @forest.reject! do |tree|
      if tree.symbol == :define
        @functions << tree
      end
    end
  end

  def generate_function(symbol, arguments, forest, is_closure = false)

      defined_arguments = arguments.each_with_index.map do |a, i|
        raise "arguments to a function definition must be idents" unless a.is_a?(Token) or a.is_ident?
        stack_push a
        "#{a.symbol} := arguments[#{i}];"
      end


      [
        "func ",
        symbol,
        "(arguments []*any",
        is_closure ? "" : ", block func([]*any) *any",
        ") *any {
        if len(arguments) != #{arguments.length} {
          panic(\"Wrong number of arguments for #{symbol} - not #{arguments.length}\")
        }
        ",
        defined_arguments,
        generate_calls(forest),
        "}",
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
    end.join "\n"
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
    forest.map! { |tree| call(tree) }.flatten!
    if includereturn
      forest[-1] =  "return " + forest[-1] 
    end
    
    forest.join(';')
  end

end

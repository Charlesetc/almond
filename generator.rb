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

  def generate_functions
    @functions.map do |tree|
      function_name = tree.arguments.shift
      unless function_name and function_name.is_ident?
        raise "first argument to define must be an ident"
      end
      raise "define takes a block" unless tree.block
      raise "define's block doesn't take any arguments" if tree.block.arguments and not tree.block.arguments.empty?

      defined_arguments = tree.arguments.each_with_index.map do |a, i|
        raise "arguments to define must be idents" unless a.is_ident?
        stack_push a
        "#{a.symbol} := arguments[#{i}];"
      end


      [
        "func ",
        function_name.symbol,
        "(arguments []*any, block func([]*any) *any) *any {
        if arguments.len() != #{tree.arguments.length} {
          panic(\"Wrong number of arguments for #{function_name.symbol} - not #{tree.arguments.length}\")
        }
        ",
        defined_arguments,
        generate_calls(tree.block.forest),
        "}\n\n",
      ].join
    end.join "\n"
  end

  def generate_headers
    "package main\n"  # No includes yet
  end

  def generate_main
    [
      "
      func main() {
      ",
      generate_calls(@forest),
      "
      }
      ",
    ].join
  end

  def generate_calls(forest)
    forest.map { |tree| call(tree) }.join(';')
  end

end

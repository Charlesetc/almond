
require_relative './data.rb'

class Generator

  module Tree

    def self.call(tree)
      [
        tree.name.symbol,
        "([",
        tree.arguments.length,
        "]*any{",
        arguments(tree),
        ",",
        block(tree),
        "})",
      ].join
    end

    def self.arguments(tree)
      tree.arguments.reduce('') do |output, argument|
        output + ',' + Tree.call(argument)
      end
    end

    def self.block(tree)
      return 'nil' if (
        tree.block.nil? or
        tree.block.arguments.empty?
      )
      [
        "func (",
        tree.block.arguments.map {|x| x.symbol }.join(", "), 
        ")",
        "{",
        Generator.generate_calls(tree.block.forest),
        "}",
      ].join
    end

  end

  def initialize(forest)
    @forest = forest
    @position = Position.new
    @functions = []
  end

  def generate
    ingest_forest
    [
      generate_headers,
      generate_functions,
      generate_main,
    ].join
  end

  def ingest_forest
    @forest.reject! do |tree|
      if tree.name.symbol == :define
        @functions << tree
      end
    end
  end

  def generate_functions
    # TODO: Do this.
  end

  def generate_headers
    ""  # No headers/includes yet
  end

  def generate_main
    [
      "
      func main() {
      ",
      Generator.generate_calls(@forest),
      "
      }
      ",
    ].join
  end

  def Generator.generate_calls(forest)
    forest.reduce('') do |output, tree|
      output + Tree::call(tree) + ';'
    end
  end

end

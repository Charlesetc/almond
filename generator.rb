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
    `gofmt -s /tmp/almond`
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

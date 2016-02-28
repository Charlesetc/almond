# generator.rb

require_relative './data.rb'

class Generator

  attr_accessor :if_statement

  module Tree

    def call(tree)
      case tree.name.symbol
      when :if
        raise "argument error: if takes one argument" if tree.arguments.length != 1
        raise "argument error: if takes a block" if tree.block.nil?
        output = [
          "if ",
          call(tree.arguments[0]),
          "{",
          generate_calls(tree.block.forest),
          "}",
        ].join
        self.if_statement = output
        output
      when :else
        raise "syntax error: else must follow an if" unless self.if_statement
        case tree.arguments.length
        when 0
          out = self.if_statement
          self.if_statement = nil
          output = [
            "else ",
            "{",
            generate_calls(tree.block.forest),
            "}",
          ].join
          out << output
        else
          unless tree.arguments[0].name.symbol == :if
            raise "syntax error: else can only be followed by if or {"
          end
          tree.name = tree.arguments.shift.name
          self.if_statement << "else "
          self.if_statement << call(tree)
        end
        self.if_statement = nil
        ''
      else
        self.if_statement = nil
        [
          tree.name.symbol,
          "([",
          tree.arguments.length,
          "]*any{",
          arguments(tree),
          "}, ",
          block(tree),
          ")",
        ].join
      end
    end

    def arguments(tree)
      tree.arguments.reduce('') do |output, argument|
        output + call(argument) + ','
      end
    end

    def block(tree)
      return 'nil' if (
        tree.block.nil? or
        tree.block.arguments.empty?
      )
      as = tree.block.arguments.map do |x|
        x.symbol.to_s + ' *any'
      end.join(", ")

      [
        "func (",
        as,
        ")",
        "{",
        generate_calls(tree.block.forest),
        "}",
      ].join
    end

  end

  include Tree

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

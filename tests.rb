# tests.rb

require 'shindo'
require 'pry'

require_relative 'data.rb'
require_relative 'token.rb'
require_relative 'parser.rb'
require_relative 'generator.rb'


# Just to make comparisons & literals easier.
class Expression

  def to_array
    if (not self.block or self.block.forest.length == 0) \
       and (not self.arguments or self.arguments.length == 0)
      return self.symbol
    end
    b = self.block ? {self.block.arguments.map { |x| x.symbol } => self.block.forest.map { |x| x.to_array }} : {}
    a = self.arguments ? self.arguments.map { |x| x.to_array } : []

    [self.symbol, a, b]
  end

end

class Printer
  attr_accessor :str
  def initialize(str)
    @str = str
  end
  def inspect
    
    @str.inspect + "\n" + @str
  end
  def ==(other)
    str == other.str
  end
end


class Tokenizee
  attr_accessor :tokens
end

Shindo.tests("Tokenizer") do

  def token_test(text, return_value)
    n = nil
    if return_value.is_a? Array
      n = return_value.length
      return_value.map! { |x| (x.is_a? Symbol) ? x.to_sym : x }
      return_value = [n, *return_value]
    else
      n = 1
      unless return_value.is_a? Symbol
        return_value = return_value.to_sym
      end
      return_value = [n, return_value]
    end
    returns(return_value) do
      t = Tokenizer.new text
      t.read
      return_values = t.tokens.map { |token| token.symbol }
      n = t.tokens.length
      if return_values.is_a? Array
        [n, *return_values]
      else
        [n, return_values]
      end
    end
  end

  # test number
  token_test "1234.434", :"1234.434"

  # test ident
  token_test "abcd", :abcd

  # test ident and number
  token_test "abcd 123", [:abcd, :"123"]

  # test ident with number
  token_test "abc23d 123", [:abc23d, :"123"]

  # test ident with number
  token_test "abc23d 123", [:abc23d, :"123"]

  # test punctuation with characters
  token_test "Hello.text", [:Hello, :".", :text]

  token_test "{ interesting }", [:do, :interesting, :end]

  # test some real code
  token_test "class Hello do
      some hi, there
    end",
    [:class, :Hello, :do, :"\n", :some, :hi, :",", :there, :"\n", :end]

end

Shindo.tests("Parser") do

  def parses_test(string, arrays)
    returns(arrays, string) do
      t = Tokenizer.new string
      t.read
      parser = Parser.new t.tokens
      a = parser.parse.map { |x| x.to_array }
      a
    end
  end

  parses_test "map", [:map]

  parses_test "map a b", [[:map, [:a, :b], {}]]

  parses_test "map {\nb }", [[:map, [], {[] => [:b]}]]

  parses_test "map a {;b }", [[:map, [:a], {[] => [:b]}]]

  parses_test "map a (lambda {x: b x })", [[:map, [:a, [:lambda, [], { [:x] => [[:b, [:x], {}]]}]], {}]]

  parses_test "hi there; wonderkin", [[:hi, [:there], {}], :wonderkin]

  parses_test "hi there\n wonderkin", [[:hi, [:there], {}], :wonderkin]

  parses_test "hi there {\nwonderkin}", [[:hi, [:there], {[] => [:wonderkin]}]]

  parses_test "\tif {\n\t\tprint this\n\t}", [[:if, [], {[] => [[:print, [:this], {}]]}]]

  parses_test "let (hi 3) 4", [[:let, [[:hi, [:"3"], {}], :"4"], {}]]

end

Shindo.tests("Generator") do

  def generates_test(description, almond_code, go_code)
    File.write("/tmp/almond2", go_code.strip)
    `goimports -w /tmp/almond2`
    go_code= `gofmt -s /tmp/almond2`.gsub "\t", "  "
    returns(Printer.new(go_code), description) do
      t = Tokenizer.new almond_code

      t.read
      parser = Parser.new t.tokens
      forest = parser.parse
      generator = Generator.new forest
      output = generator.generate
      Printer.new(output)
    end
  end

  generates_test  "function call with arguments",
  "call something", "
    package main
    func main() {
      call([]*any{something([]*any{}, nil)}, nil)
    }
  "

  generates_test "function call with block",
  "mapped a { c : d c }", "
    package main
    func main() {
      mapped([]*any{a([]*any{}, nil)}, func (arguments []*any) *any {
        if len(arguments) != 1 {
          panic(\"Wrong number of arguments for  - not 1\")
        }
        c := arguments[0];
        return d([]*any{c}, nil)
      })
    }
  "

  generates_test "if and else statement",
  "
    if a {
      b
    } else {
      c
    }
  ", "
    package main
    func main() {
      if a([]*any{}, nil) {
        return b([]*any{}, nil)
      } else {
        return c([]*any{}, nil)
      }
    }
  "

  generates_test "let syntax",
  "
    let a 2
    b a
  ", "
    package main
    func main() {
      a := 2([]*any{}, nil)
      a
      b([]*any{a}, nil)
    }
  "

  generates_test "define a function" ,
  "
    define a b do
      print
    end
    a b
  ", "
    package main
    func a(arguments []*any, block func([]*any) *any) *any {
        if len(arguments) != 1 {
          panic(\"Wrong number of arguments for a - not 1\")
        }
        b := arguments[0]
      return print([]*any{}, nil)
    }

    func main() {
      a([]*any{b([]*any{}, nil)}, nil)
    }
  "

  returns(false, "outputs valid gofmt") do
    t = Tokenizer.new "
    test test
    mapped a {b c : c} test
    if hi {
      print this
    } else {
      print that
    }
    let hi this that wow
    let hi 2

    mapped {
      let next hi
    }

    define hi this that do
      somefunction this that
    end
    "
    t.read
    parser = Parser.new t.tokens
    forest = parser.parse
    generator = Generator.new forest
    output = generator.generate
    output.empty?
  end

end

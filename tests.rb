# tests.rb

require 'shindo'
require 'pry'

require_relative 'data.rb'
require_relative 'token.rb'
require_relative 'parser.rb'


# Just to make comparisons & literals easier.
class Expression

  def to_array
    if (not self.block or self.block.forest.length == 0) \
       and (not self.arguments or self.arguments.length == 0)
      return self.name.symbol
    end
    b = self.block ? {self.block.arguments.map { |x| x.symbol } => self.block.forest.map { |x| x.to_array }} : {}
    a = self.arguments ? self.arguments.map { |x| x.to_array } : []

    [self.name.symbol, a, b]
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

  parses_test "map a {;b }", [[:map, [:a], {[] => [:b]}]]

  parses_test "map a (lambda {x: b x })", [[:map, [:a, [:lambda, [], { [:x] => [[:b, [:x], {}]]}]], {}]]

  parses_test "hi there; wonderkin", [[:hi, [:there], {}], :wonderkin]

  parses_test "hi there\n wonderkin", [[:hi, [:there], {}], :wonderkin]

  parses_test "hi there {\nwonderkin}", [[:hi, [:there], {[] => [:wonderkin]}]]

end

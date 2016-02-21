require_relative './main.rb'

require 'shindo'
require 'pry'

class Tokenizer
  attr_accessor :tokens
end

# Test tokenizer
Shindo.tests do

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

  # test punctuation
  token_test "?\n;", [:"?", :newline, :newline]

  # test punctuation with characters
  token_test "Hello.text", [:Hello, :".", :text]

end

# tokenizer.rb

require_relative 'data.rb'

class Tokenizer
  attr_accessor :tokens

  def initialize(text)
    @chars = text.chars.reverse
    @tokens = []
    @line = 0
    @column = 0
    @character = 0
  end

  def read
    read_start next_char
  end

  def read_start(a)
    case
    when a == nil
      return
    when a.numeric?
      read_number a
    when a.alpha?
      read_ident a
    when ' \t'.include?(a)
      read
    else
      read_punct a
    end
  end

  def read_number(a)
    tok, a = read_characters a, :numeric?
    if a == '.'
      decimal, a = read_characters a, :numeric?
      token tok + decimal
    else
      token tok
    end
    read_start a
  end

  def read_ident(a)
    tok, a = read_characters a, :alphanumeric?
    token tok
    read_start a
  end

  def read_characters(a, method)
    ident = [a]
    while (a = next_char) and a.send method
      ident << a
    end
    return ident.join(''), a
  end

  def read_punct(a)
    token (CHAR_MAPPING[a] || a)
    read
  end

  def token(a)
    unless a.is_a? Symbol
      a = a.to_sym
    end
    @tokens << Token.new(a, @line, @column, @character)
  end

  def next_char
    a = @chars.pop
    @character += 1
    @column += 1
    if a == '\n'
      @column = 0
      @line += 1
    end
    a
  end
  
end

class Expression
  attr_accessor :name, :arguments, :block
  @@indentation = 0

  def initialize(name, arguments, block)
    @name = name
    @arguments = arguments
    @block = block
  end

  def inspect
    output = ""
    output += "#{@name.symbol}"

    @@indentation += 1

    if @arguments and @arguments.length > 0
      output += "("
      first = true
      arguments.each do |a|
        if first
          first = false
        else
          output += ", "
        end
        output += a.inspect
      end
      output += ")"
    end

    if @block and @block.length > 0
      output += " {\n"
      @block.each do |b|
        output += indentation
        output += b.inspect
      end
      @@indentation -= 1
      output += "\n#{indentation}}"
    else
      @@indentation -= 1
    end
    total_string = "@name"

    output
  end

  def indentation
    ("  " * @@indentation)
  end
end


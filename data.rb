# data.rb

require 'pry'

OPERATORS = {
  :'=' => 0.0,
  :== => 0.1,
  :+ => 0.2,
  :- => 0.2,
  :* => 0.3,
  :/ => 0.3,
  :^ => 0.4,
}

CHAR_MAPPING = {
  ";" => :"\n",
  "\n" => :"\n",
  ":" => :"\n",

  "}" => :end,
  "{" => :do,
  "]" => ")" # to support lists
}

# Used for bindings.
TYPE_MAPPING = {
  int: "INT",
  float32: "FLOAT",
  string: "STRING",
  bool: "BOOL",
}

# Move to this away from that ^^
GO_BUILTIN_TYPES = [
	[:INT, :int],
	[:FLOAT, :float32],
	[:STRING, :string],
	[:NIL, :nil],
	[:BOOL, :bool],
	[:ARRAY, :array],
	[:LAMBDA, :lambda],
]

NUMBER_OF_TYPES = GO_BUILTIN_TYPES.length

KEYWORDS = [:do, :"\n", :end]

def hzl_namespace(name)
  name = name.to_s
  name.gsub! "+", "___plus___"
  name.gsub! ".", "___dot___"
  name.gsub! "*", "___star___"
  name.gsub! "%", "___percentage___"
  name.gsub! "?", "___question___"
  name.gsub! "=", "___equals___"
  name.gsub! "-", "___minus___"
  "hzl_" + name
end

class String

  def alpha?
    self =~ /^[[:alpha:]\.\-?=%$^_+@*]+$/
  end

  def numeric?
    self =~ /^[[:digit:]]+$/
  end

  def alphanumeric?
    self =~ /^[[:alpha:]\-_=%?$^+@*[:digit:]]+$/
  end

  def quote?
    self == "'" or self == '"'
  end
  
end

class Token
  attr_accessor :symbol, :position

  def initialize(symbol, position)
    @symbol = symbol
    @position = position
  end

  def newline?
    self.symbol == :"\n"
  end

  def end?
    self.symbol == :end
  end

  def do?
    self.symbol == :do
  end

  def operator?
    OPERATORS.include?(self.symbol)
  end
end

class Position

  attr_accessor :line, :column, :character

  def initialize
    @line = 0
    @column = 0
    @character = 0
  end

  def increment(a)
    @character += 1
    @column += 1
    if a == "\n"
      @column = 0
      @line += 1
    end
  end

end

class Block
  attr_accessor :forest, :arguments

  def initialize(forest, arguments)
    @forest = forest
    @arguments = arguments
  end
end

class Expression
  attr_accessor :name, :arguments, :block
  @@indentation = 0

  def initialize(name, arguments=[], block=nil)
    @name = name
    @arguments = arguments
    @block = block
  end

  # TODO: Make these two methods cleaner
  def dot_syntax?
    symbol.to_s[0] == '.' and symbol.to_s.length > 1 and self.arguments.empty? and not self.block
  end

  def dot_syntax_with_call?
    symbol.to_s[0] == '.' and symbol.to_s.length > 1
  end

  def is_ident?
    self.arguments.empty? and not self.block and self.name.symbol.to_s[0].alpha?
  end

  def is_string?
    self.arguments.empty? and not self.block and self.name.symbol.to_s[0].quote?
  end

  def symbol
    self.name.symbol
  end

  # This is just pretty-printing for debugging
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

    if @block and @block.forest.length > 0
      output += " {\n"
      @block.forest.each do |b|
        output += indentation
        output += b.inspect
      end
      @@indentation -= 1
      output += "\n#{indentation}}"
    else
      @@indentation -= 1
    end

    output
  end

  # also for pretty-printing
  def indentation
    ("  " * @@indentation)
  end

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

# data.rb

CHAR_MAPPING = {
  ";" => :"\n",
  "\n" => :"\n",
  "}" => :end,
  "{" => :do,
  ":" => :"\n",
}

KEYWORDS = [:do, :"\n", :end]

class String

  def alpha?
    self =~ /^[[:alpha:]]+$/
  end

  def numeric?
    self =~ /^[[:digit:]]+$/
  end

  def alphanumeric?
    self =~ /^[[:alpha:][:digit:]]+$/
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

  def initialize(name, arguments, block)
    @name = name
    @arguments = arguments
    @block = block
  end

  def is_ident?
    self.arguments.empty? and not self.block and self.name.symbol.to_s[0].alpha?
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

  # also for pretty-printing
  def indentation
    ("  " * @@indentation)
  end
end

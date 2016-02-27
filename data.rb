# data.rb

CHAR_MAPPING = {
  ";" => :"\n",
  "\n" => :"\n",
  "}" => :end,
  "{" => :do,
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
  attr_accessor :line, :symbol, :column, :character
  def initialize(symbol, line, column, character)
    @symbol = symbol
    @line = line
    @column = column
    @character = character
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

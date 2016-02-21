
CHAR_MAPPING = {
  ";" => :newline,
  "\n" => :newline,
}

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
end

class Tokenizer

  def initialize(text)
    @chars = text.chars.reverse
    @tokens = []
    @line = 0
    @column = 0
    @character = 0
  end

  def read
    read_start pop
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
    while (a = pop) and a.send method
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

  def pop
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

class Parser
  
  def initialize(text)
    @text = text
  end

end

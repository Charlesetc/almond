
CHAR_MAPPING = {
  ";" => :newline,
  "\n" => :newline,
  "}" => :end,
  "{" => :do,
}

KEYWORDS = [:do, :newline, :end]

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
    self == :"\n"
  end

  def end?
    self == :end
  end

  def do?
    self == :do
  end
end

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

  def initialize(name, arguments, block)
    @name = name
    @arguments = arguments
    @block = block
  end

  def inspect
    "#{@name.symbol}(#{arguments}) {
      #{block}
    }"
  end
end

class Parser
  
  def initialize(tokens)
    @tokens = tokens.reverse
    @character = 0
    @column = 0
    @line = 0
  end

  def parse
    parse_functions next_token
  end

  def parse_functions(token, trees=[])
    return trees unless token
    return trees if token.end?
    return parse_funcitons next_token, trees if token.newline?

    tree, a = parse_function token
    trees << tree
    parse_functions a, trees
  end

  def parse_function(token)
    raise "No newlines" if token.newline?
    raise "The end is nigh" if token.end?

    name = token
    arguments, a = parse_arguments next_token
    block = parse_block a
    Expression.new name, arguments, block
  end

  def parse_arguments(token, arguments=[])
    case token
    when nil
      return arguments, token
    when :do, :newline, :")"
      return arguments, token
    when :"("
      arguments << (parse_function token)
    else
      arguments << (Expression.new token, [], [])
    end
    parse_arguments next_token, arguments
  end

  def parse_block(token)
    return nil unless token
    if token.do?
      parse_functions next_token
    end
  end

  def next_token
    token = @tokens.pop
    return nil unless token
    @line = token.line
    @column = token.column
    @character = token.character
    token
  end

end

# parser.rb

require_relative 'data.rb'

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
    return trees if token.end? or token.symbol == :")"
    return parse_functions next_token, trees if token.newline?

    tree, a = parse_function token
    trees << tree
    parse_functions a, trees
  end

  def parse_function(token)
    raise "No newlines" if token.newline?
    raise "The end is nigh" if token.end?

    if token.symbol == :"("
      return parse_function(next_token)
    end

    name = token
    arguments, a = parse_arguments next_token
    block, a = parse_block a
    return Expression.new(name, arguments, block), a
  end

  def parse_arguments(token, arguments=[])
    return arguments, token unless token
    case token.symbol
    when :do, :"\n" , :")", :end
      return arguments, token
    when :"("
      argument, a = parse_function token
      arguments << argument
      return parse_arguments a, arguments
    else
      arguments << (Expression.new token, [], [])
    end
    parse_arguments next_token, arguments
  end

  def parse_block(token)
    return nil unless token
    if token.do?
      return parse_functions(next_token), next_token
    else
      return nil, token
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

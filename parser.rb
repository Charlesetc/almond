# parser.rb

require_relative 'data.rb'

class Parser
  
  def initialize(tokens)
    @tokens = tokens.reverse
    @position = Position.new
  end

  def parse
    parse_functions next_token
  end

  def parse_functions(token, forest=[])
    return forest unless token
    return forest if token.end? or token.symbol == :")"
    return parse_functions next_token, forest if token.newline?

    tree, a = parse_function token
    forest << tree
    parse_functions a, forest
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
      arguments << (Expression.new token, [], nil)
    end
    parse_arguments next_token, arguments
  end

  def parse_block_arguments(token, arguments=[])
    case token.symbol
    when :do
      raise "this would be a problem. #{arguments}" unless arguments.empty?
    when :"\n", :"(", :")", :end
      return arguments, token
    else
      arguments << token
    end
    parse_block_arguments(next_token, arguments)
  end

  def parse_block(token)
    return nil unless token
    if token.do?
      arguments, a = parse_block_arguments next_token
      forest = parse_functions a
      return Block.new(forest, arguments), next_token
    else
      return nil, token
    end
  end

  def next_token
    token = @tokens.pop
    return nil unless token
    @position = token.position
    token
  end

end

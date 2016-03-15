# parser.rb

require_relative 'data.rb'

class Parser
  attr_reader :current
  
  def initialize(tokens)
    @tokens = tokens.reverse
    @position = Position.new
    @current = nil
  end

  def parse
    next_current
    forest = parse_functions
    # It might be a good place to alert errors if there's a token
    # TODO: Find out what the normal ending scenario for this should be.
    # It is probably nil.

    forest
  end

  def parse_functions(forest=[])
    return forest unless current
    return forest if current.end? or current.symbol == :")"

    if current.newline?
      next_current
      return parse_functions forest
    end

    tree = parse_function
    forest << tree
    parse_functions forest
  end
  
  def parse_function
    raise "No newlines" if current.newline?
    raise "The end is nigh" if current.end?

    if current.symbol == :"("
      next_current
      return parse_function
    end

    name = current
    next_current
    return Expression.new(name, parse_arguments, parse_block)
  end

  def parse_arguments(arguments=[])
    return arguments unless current
    case current.symbol
    when :do, :"\n" , :")", :end
      return arguments
    when :"("
      argument = parse_function
      arguments << argument
      raise "This shouldn't happen. This is a bug" unless current.symbol == :")"
      next_current
      return parse_arguments arguments
    else
      if current.operator?
        return arguments
      end
      arguments << (Expression.new current, [], nil)
    end
    next_current
    parse_arguments arguments
  end

  def parse_block_arguments(arguments=[])
    case current.symbol
    when :do
      raise "this would be a problem. #{arguments}" unless arguments.empty?
    when :"\n", :"(", :")", :end
      return arguments
    else
      arguments << current
    end
    next_current
    parse_block_arguments(arguments)
  end

  def parse_block
    return nil unless current
    if current.do?
      next_current
      arguments = parse_block_arguments
      forest = parse_functions
      # DO SOMETHING WITH current at this point in time
      raise "I have asserted that this shouldn't happen" unless current.end?

      next_current
      return Block.new(forest, arguments)
    elsif current.operator?
      # I feel like this is wrong
      # actually, I think it's right
      return nil
    else
      return nil
    end
  end

  def next_current
    token = @tokens.pop
    unless token
      @current = nil 
      return
    end

    @position = token.position
    @current = token
  end

end

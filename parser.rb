# parser.rb

require_relative 'data.rb'


class ShuntingBox
  attr_accessor :operator_stack, :postfix_stack

  def initialize
    @operator_stack = []
    @postfix_stack = []
  end

  def put(tree)
    postfix_stack << tree
  end

  def put_operator(operator)
    if (op = operator_stack.pop)
      if precedence(op) < precedence(operator)
        # operator binds more tightly
        operator_stack << op
        operator_stack << operator
      elsif precedence(op) > precedence(operator)
        put operator
        put_operator(operator)
      else # They are equal
        operator_stack << op
        operator_stack << operator
      end
    else
      operator_stack << operator
    end
  end

  def look_inside
    # Pop the operators off one by one
    @postfix_stack += @operator_stack.reverse

    convert_to_tree @postfix_stack
  end

  def convert_to_tree(stack)
    raise "but don't operators take arguments?" if stack.empty?

    item = stack.pop

    if is_operator?(item)
      raise "operators also take 2 argumenst" if stack.length == 1

      # hardcoded two arguments for an operator
      a1 = convert_to_tree(stack)
      a2 = convert_to_tree(stack)

      return Expression.new(item, [a1, a2], nil)
    else
      return item
    end
  end

  # Helper methods

  def precedence(operator)
    OPERATORS[operator.symbol]
  end

  def is_operator?(item)
    # Distinguishing based on class...
    item.is_a? Token
  end

end

module Transformations

  def transform_dot_preceeding(tree)
    if tree.dot_syntax_with_call?
      name_symbol = ('"' + tree.symbol.to_s[1..-1] + '"').to_sym
      name = tree.name.clone
      name.symbol = name_symbol

      receiver = tree.arguments.shift
      raise "Receiver should not be none" unless receiver
      tree.arguments.unshift Expression.new(name)
      tree.arguments.unshift receiver
      tree.name.symbol = :"."
    end

    # Map over the rest of the tree
    tree.arguments.each { |x| transform_dot_preceeding x }
    tree.block and tree.block.forest.each { |x| transform_dot_preceeding x }
  end

  def transform_dot_syntax(tree)

    # The first argument is handled differently because it would be
    # a method call.
    first_a = tree.arguments[0]
    if first_a and first_a.dot_syntax?
      old_name = tree.name
      tree.name = first_a.name
      first_a.name = old_name
      # poifect
    end

    # Skips the first one
    last_a = nil
    tree.arguments.reverse!.reject! do |a|
      if (keep = (last_a and last_a.dot_syntax?))
        # The old switcheroo
        inner = Expression.new(last_a.name, last_a.arguments, last_a.block)
        last_a.arguments = [inner]
        last_a.name = a.name
        last_a.block = a.block
      else
        last_a = a
      end
      keep
    end
    tree.arguments.reverse!

    # Map over the rest of the tree
    tree.arguments.each { |x| transform_dot_syntax x }
    tree.block and tree.block.forest.each { |x| transform_dot_syntax x }
  end

end

class Parser
  attr_reader :current

  include Transformations
  
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

    forest.each { |x| transform_dot_syntax x }
    forest.each { |x| transform_dot_preceeding x }

    forest
  end

  def parse_functions(forest=[])
    return forest unless current
    return forest if current.end? 
    if current.symbol == :")"
      next_current
      return parse_functions(forest)
    end

    if current.newline?
      next_current
      return parse_functions forest
    end

    tree = parse_intelligent_fuction
    forest << tree
    parse_functions forest
  end

  def parse_intelligent_fuction(box=ShuntingBox.new)
    tree = operatorless_function
    if current and current.operator?

      box.put tree
      box.put_operator current

      next_current

      return parse_intelligent_fuction box
    end
    box.put tree
    box.look_inside
  end
  
  def operatorless_function
    raise "No newlines" if current.newline?
    raise "The end is nigh" if current.end?

    if current.symbol == :"("
      next_current
      return operatorless_function
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
      argument = parse_intelligent_fuction
      arguments << argument
      raise "This shouldn't happen. This is a bug" unless current.symbol == :")"
      next_current
      return parse_arguments arguments
    else
      if current.operator?
        return arguments
      end
      arguments << (Expression.new current)
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

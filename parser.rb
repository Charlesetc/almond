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

  def put_operator(new_op)
    if (old_op = operator_stack.pop)
      if precedence(old_op) < precedence(new_op)
        # new_op binds more tightly
        operator_stack << old_op
        operator_stack << new_op
      elsif precedence(old_op) > precedence(new_op)
        put(old_op) #one of these is wrong
        put_operator(new_op)
      else # They are equal
        # I'm not taking into account associatitivy
        operator_stack << old_op
        operator_stack << new_op
      end
    else
      operator_stack << new_op
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
      raise "operators also take 2 arguments" if stack.length == 1

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

  ##
  ## Moves (".test" hi) to ("." hi "test")
  ##
  def transform_dot_preceeding(tree)
    if tree.dot_syntax_with_call?
      name_symbol = ('"' + tree.symbol.to_s[1..-1] + '"').to_sym
      name = tree.name.clone
      name.symbol = name_symbol

      receiver = tree.arguments.shift
      unless receiver
        raise "Receiver should not be none"
      end
      tree.arguments.unshift Expression.new(name)
      tree.arguments.unshift receiver if receiver
      tree.name.symbol = :"."
    end

    # Map over the rest of the tree
    tree.arguments.each { |x| transform_dot_preceeding x }
    tree.block and tree.block.forest.each { |x| transform_dot_preceeding x }
  end

  def get_last_dotted_argument(as)
  end

  ##
  ## Moves (this test.that) to (this (.that test))
  ## and (test.five there) to (.five test there)
  ##
  def transform_dot_syntax(tree)
    leading_arguments = []
    while (a = tree.arguments.shift)
      if a.dot_syntax?
        leading_arguments << a
      else
        tree.arguments.unshift a
        break
      end
    end

    # Transform a.one.two into (.two (.one a))
    recursing_tree = tree
    while priority_method = leading_arguments.pop
      old_name = recursing_tree.name
      recursing_tree.name = priority_method.name
      priority_method.name = old_name
      recursing_tree.arguments.unshift priority_method
      recursing_tree = priority_method
    end

    last_a = nil
    next_arguments = []
    tree.arguments.reject! do |a|
      should_reject = (last_a and a.dot_syntax?)
      if should_reject
        next_arguments << a
      else
        next_arguments.each do |next_a|
          last_a.arguments << next_a
        end
        next_arguments = []
        last_a = a
      end
      should_reject
    end
    next_arguments.each do |next_a|
      last_a.arguments << next_a
    end

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

    if current and current.symbol == :")"
      next_current
    end

    box.put tree
    box.look_inside
  end
  
  def operatorless_function
    raise "No newlines" if current.newline?
    raise "The end is nigh" if current.end?

    if current.symbol == :"("
      next_current

      function = parse_intelligent_fuction
      arguments = parse_arguments
      block = parse_block

      return function unless (arguments and not arguments.empty?) or block
      return Expression.new(function, arguments, block)
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
      next_current
      argument = parse_intelligent_fuction
      arguments << argument

      return arguments unless current

      # This is possibly the worst code I've written.

      if current.symbol == :"\n"
        return arguments
      end

      if current.symbol == :")"
        next_current
      end
      if current and current.symbol == :")"
        next_current
        return arguments + parse_arguments
      end

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
      raise "I have asserted that this shouldn't happen" unless  current.end?

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

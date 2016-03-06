# generator/call_tree.rb

module Tree

  @@token_functions = {}
  @@token_predicates = []
  @@stacks = [[]]

  ### A DSL for matching against certain tokens. ###

  def self.match(token, &block)
    if token.respond_to? :call
      @@token_predicates << [token, block]
    else
      @@token_functions[token] = block
    end
  end

  match :if do |tree|
    raise "argument error: if takes one argument" if tree.arguments.length != 1
    raise "argument error: if takes a block" if tree.block.nil?
    output = [
      "if ",
      call(tree.arguments[0]),
      "{",
      generate_calls(tree.block.forest),
      "}",
    ].join
    self.if_statement = output
    output
  end

  match :else do |tree|
    raise "syntax error: else must follow an if" unless self.if_statement
    if tree.arguments.length == 0
      previous_if = self.if_statement
      self.if_statement = nil
      previous_if << [
        "else ",
        "{",
        generate_calls(tree.block.forest),
        "}",
      ].join
    else
      unless tree.arguments[0].symbol == :if
        raise "syntax error: else can only be followed by if or {"
      end
      tree.name = tree.arguments.shift.name
      self.if_statement << "else "
      self.if_statement << call(tree)
    end
    self.if_statement = nil
    ''
  end

  match :let do |tree|
    raise "let does not take a block" if tree.block
    raise "let needs an even number of arguments" unless tree.arguments.length % 2 == 0

    tree.arguments.each_slice(2).map do |ident, value|
      raise "'let' takes identifier - expression pairs as arguments" unless ident.is_ident?

      if @@stacks.last.include?(ident.symbol)
        equals = "="
      else
        equals = ":="
        stack_push ident
      end
      
      result = call(value)
      if result.is_a?(Array) and result.length > 1 
        preceding = result
        result = result.pop
      else
        preceding = ""
      end

      [
        preceding,
        [ident.symbol, equals, result, "\n"].join,
        equals == ":=" ? ident.symbol.to_s : ""
      ]
    end
  end

  # Integer and Float constants.
  match lambda { |symbol| symbol.to_s[0].numeric? } do |tree|
    raise "Numbers do not take a block" if tree.block
    raise "Numbers do not take any arguments" if tree.arguments.length != 0
    if tree.symbol.to_s.include? "."
      type = 'FLOAT'
    else
      type = 'INT'
    end
    tmp = temp_var
    [
      "#{tmp} := #{tree.symbol}\n",
      "into_any(#{type}, unsafe.Pointer(&#{tmp}))"
    ]
  end

  ### Other Functions that are key to generating function calls ###

  def call(tree)
    function = @@token_functions[tree.symbol]
    return self.instance_exec(tree, &function) if function

    @@token_predicates.each do |predicate, function|
      return self.instance_exec(tree, &function) if predicate.call(tree.symbol)
    end

    call_normal_function(tree)
  end

  def call_normal_function(tree)
    self.if_statement = nil

    if tree.is_ident? and @@stacks.flatten.include? tree.symbol
      return tree.symbol.to_s
    end
    definitions, args = arguments(tree)
    [
      definitions,
      [
        tree.symbol,
        "(",
        args,
        ",",
        block(tree),
        ")",
      ].join
    ]
  end

  def stack_push(expression)
    @@stacks.last << expression.symbol
  end

  def arguments(tree)
    definitions = []
    as = tree.arguments.reduce('') do |output, argument|
        result = call(argument)
        if result.is_a?(Array)
          these_definitions = result
          result = these_definitions.pop
          definitions += these_definitions
        end
        output + result + ','
    end
    return definitions, [
      "[]*any{",
      as,
      "}",
    ].join
  end

  def block(tree)
    return 'nil' if (
      tree.block.nil?
    )

    enter_stack
    output = generate_function("", tree.block.arguments, tree.block.forest, true)
    exit_stack
    return output
  end

  def enter_stack
    @@stacks << []
  end

  def exit_stack
    @@stacks.pop
  end

  def temp_var
   "temp_" + rand.hash.abs.to_s[0, 10]
  end

end

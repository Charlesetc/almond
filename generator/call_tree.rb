# generator/call_tree.rb

class FunctionCall
  attr_accessor :prerequisites, :body, :return_value
  def initialize(body, prerequisites="", rvalue=body)
    @prerequisites = prerequisites
    @body = body
    @return_value = rvalue
  end
end

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

  def self.alias_symbol(hzl_symbol, go_symbol)
    match hzl_symbol do |tree|
      fn = call_normal_function(tree)
      fn.body.sub!  hzl_symbol.to_s, go_symbol.to_s # this might be terrible
      fn
    end
  end

  # alias_symbol :".=", :set_struct_member
  # alias_symbol :".", :get_struct_member

  match :if do |tree|
    raise "argument error: if takes one argument" if tree.arguments.length != 1
    raise "argument error: if takes a block" if tree.block.nil?
    fn = call(tree.arguments[0])
    fn.body = [
      "if from_bool(",
      fn.body,
      "){",
      generate_calls(tree.block.forest, false),
      "}",
    ].join
    self.if_statement = fn
  end

  match :else do |tree|
    # TODO: This can be refactored to be better.
    raise "syntax error: else must follow an if" unless self.if_statement
    if tree.arguments.length == 0
      previous_if = self.if_statement
      self.if_statement = nil
      previous_if.body << [
        "else ",
        "{",
        generate_calls(tree.block.forest, false),
        "}",
      ].join
    else
      unless tree.arguments[0].symbol == :if
        raise "syntax error: else can only be followed by if or {"
      end
      tree.name = tree.arguments.shift.name
      self.if_statement.body << "else "
      fn = call(tree)
      self.if_statement.prerequisites << fn.prerequisites
      self.if_statement.body << fn.body
      self.if_statement.return_value = fn.return_value
    end
    self.if_statement = nil
    FunctionCall.new('') # Should be a no-op because we added it to the if.
  end

  match :"=" do |tree|
    raise "= does not take a block" if tree.block
    raise "= takes two arguments" unless tree.arguments.length == 2
    value, assignee = tree.arguments

    if assignee.is_ident?
      if @@stacks.last.include?(assignee.symbol)
        equals = "="
      else
        equals = ":="
        stack_push assignee
      end

      name = hzl_namespace(assignee.symbol)
      
      fn = call(value)
      preceeding = fn.prerequisites
      body = [name, equals, fn.body, "\n"].join
      FunctionCall.new(body, preceeding, name)
    elsif assignee.symbol == :"."
      raise "cannot assign to function call" unless assignee.arguments.length == 2
      assignee.arguments.push value
      assignee.name.symbol = :".="
      call_normal_function(assignee)
    else
      binding.pry
      raise "'=' needs a valid identifier to assign to"
    end
  end

  match :new do |tree|
    raise "new does not take a block" if tree.block
    raise "new takes one argument" if tree.arguments.length != 1
    name = tree.arguments[0].symbol
    fields, i = @struct_definitions[name]

    raise "No such struct defined #{name}" unless fields

    temp = temp_var
    preceeding = [
      temp,
      ":= []*any{",
      fields.map { |_| "into_any(NIL, nil)" }.join(","),
      "}\n"
    ].join

    body = "into_any(#{i}, unsafe.Pointer(&#{temp}))"

    FunctionCall.new(
      body,
      preceeding,
    )
  end

  match :list do |tree|
    raise "list does not take a block" if tree.block
    preceeding = ''
    body = '[]*any{'
    seperator = ''
    tree.arguments.map do |item|
      fn = call(item)

      preceeding += fn.prerequisites
      body += seperator
      body += fn.body
      seperator = ', '
    end
    body += '}'
    temp = temp_var
    preceeding += "\n#{temp} := #{body}\n"
    FunctionCall.new(
      "into_any(ARRAY, unsafe.Pointer(&#{temp}))",
      preceeding,
    )
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
    definition = "#{tmp} := #{tree.symbol}\n"
    body= "into_any(#{type}, unsafe.Pointer(&#{tmp}))"
    FunctionCall.new(body, definition)
  end

  # String constants
  match lambda { |symbol| symbol.to_s[0].quote? } do |tree|
    raise "Strings do not take a block" if tree.block
    raise "Strings do not take any arguments" if tree.arguments.length != 0
    tmp = temp_var
    content = tree.symbol.to_s[1..-2]
    FunctionCall.new(
      "into_any(STRING, unsafe.Pointer(&#{tmp}))", # body
      "#{tmp} := \"#{content}\"\n" # preceeding
    )
  end

  ### Other Functions that are key to generating function calls ###

  def call(tree)
    function = @@token_functions[tree.symbol]
    return self.instance_exec(tree, &function) if function

    @@token_predicates.each do |predicate, function|
      if predicate.call(tree.symbol)
        fn = self.instance_exec(tree, &function)
        return fn
      end
    end

    call_normal_function(tree)
  end

  def call_normal_function(tree)
    self.if_statement = nil

    if tree.is_ident? and @@stacks.flatten.include? tree.symbol
      return FunctionCall.new(hzl_namespace(tree.symbol))
    end
    fn = arguments(tree)
    fn.body = [
             hzl_namespace(tree.symbol),
             "(",
             fn.body,
             ",",
             block(tree),
             ")",
           ].join
     fn.return_value = fn.body
     fn
  end

  def stack_push(expression)
    @@stacks.last << expression.symbol
  end

  def arguments(tree)
    fn_acc = tree.arguments.reduce(FunctionCall.new("")) do |fn_acc, argument|
        fn = call(argument)
        fn_acc.prerequisites += fn.prerequisites
        fn_acc.return_value = fn.return_value

        fn_acc.body += fn.body
        fn_acc.body += ","
        fn_acc
    end
    fn_acc.body = "[]*any{#{fn_acc.body}}"
    fn_acc
  end

  def block(tree)
    return 'nil' if not tree.block

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
    @i ||= 0
    @i += 1
   "hazelnut_#{@i}"
  end

end

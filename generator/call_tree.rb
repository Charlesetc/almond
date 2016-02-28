# generator/call_tree.rb

module Tree

  @@token_functions = {}

  def self.match(token, &block)
    @@token_functions[token] = block
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
      unless tree.arguments[0].name.symbol == :if
        raise "syntax error: else can only be followed by if or {"
      end
      tree.name = tree.arguments.shift.name
      self.if_statement << "else "
      self.if_statement << call(tree)
    end
    self.if_statement = nil
    ''
  end

  def call(tree)
    function = @@token_functions[tree.name.symbol]
    return self.instance_exec(tree, &function) if function
    call_normal_function(tree)
  end

  def call_normal_function(tree)
    self.if_statement = nil
    [
      tree.name.symbol,
      "([",
      tree.arguments.length,
      "]*any{",
      arguments(tree),
      "}, ",
      block(tree),
      ")",
    ].join
  end

  def arguments(tree)
    tree.arguments.reduce('') do |output, argument|
      output + call(argument) + ','
    end
  end

  def block(tree)
    return 'nil' if (
      tree.block.nil? or
      tree.block.arguments.empty?
    )
    as = tree.block.arguments.map do |x|
      x.symbol.to_s + ' *any'
    end.join(", ")

    [
      "func (",
      as,
      ")",
      "{",
      generate_calls(tree.block.forest),
      "}",
    ].join
  end

end

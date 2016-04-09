# generator/struct.rb

require_relative '../data.rb'

# TODO: Make function definitions as neat as this.
#       Standardize the api for pluggins.
module Structs

  def ingest_struct(tree)
    if tree.arguments.length != 1
      raise "struct takes one argument"
    end
    if not tree.block
      raise "struct takes a block"
    end
    if tree.block.arguments and tree.block.arguments.length != 0
      raise "struct's block does not take arguments"
    end

    tree.block.forest.each do |tree|
      unless tree.is_ident?
        raise "struct's block must be a list of idents"
      end
    end


    @struct_count ||= NUMBER_OF_TYPES - 1
    @struct_count += 1
    @struct_definitions[tree.arguments[0].symbol] = [tree.block.forest.map { |t| t.symbol }, @struct_count]
  end

  def construct_def(name, members, methods)
      [
        "definition{",
        "name:",
          '"',
          name,
          '",',
        "members:",
          "[]string{",
          members.map { |x| '"' + x.to_s + '"' }.join(", "),
          "},",
        "methods:",
          "[]method{",
            methods.join(","),
          "},",
        "}",
      ].join
  end

  def struct_init
    inner_list = @struct_definitions.map do |name, data|
      symbols, i = data

      if GO_BUILTIN_TYPES.map {|x, y| y}.include? name
        next
      end

      methods = generate_methods(name)
      construct_def(name, symbols, methods)
    end.join(",\n")

    builtin_definitions = GO_BUILTIN_TYPES.map do |gotype, type|
      exprs = @methods[type]
      if exprs 
        symbols = exprs.map { |e| e.symbol }
        methods = generate_methods(type)
        construct_def(type, symbols, methods)
      else 
        construct_def(type, [], [])
      end
    end.join(",\n")

    [
      "struct_definitions = []definition{",
        builtin_definitions,
        ",",
        inner_list,
      "}"
    ].join
  end

  def struct_headers
    "\nvar struct_definitions []definition\n"
  end

  def generate_methods(name)
    methods = @methods[name]
    if methods
      methods.map do |tree|
        if tree.block
          tree.block.arguments.unshift(Expression.new(Token.new(:self, Position.new)))
        end
        stack_name = "#{method_name(tree).to_s[1..-2]} method of #{name}"
        [
          "{",
          method_name(tree),
          ",",
          block(tree, "\n_ = hzl_self\n", stack_name), # Avoid go's weird rules.
          "}",
        ].join
      end
    else
      []
    end
  end

  def method_name(tree)
    tree.arguments[0].arguments[1].symbol
  end

end

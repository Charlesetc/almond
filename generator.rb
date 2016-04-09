# generator.rb

require_relative './data.rb'
require_relative './generator/call_tree.rb'
require_relative './generator/struct.rb'

class Generator

  include Tree
  include Structs

  attr_accessor :if_statement

  def initialize(forest)
    @forest = forest
    @functions = []
    @methods = {}
    @bindings = []
    @struct_definitions = {}
  end

  def generate
    ingest_forest
    output = [
      generate_headers,
      generate_main,
    ].join
    File.write("/tmp/hazelnut", output)
    `goimports -w /tmp/hazelnut`
    `gofmt -s /tmp/hazelnut`.gsub "\t", "  "
  end

  def ingest_forest
    @forest.reject! do |tree|
      if tree.symbol == :define
        first_a = tree.arguments[0]
        if first_a and first_a.symbol == :'.'
          if first_a.arguments.length != 2
            raise "First argument to define is invalid"
          end
          struct_name = first_a.arguments[0].symbol
          @methods[struct_name] ||= []
          @methods[struct_name] << tree
        else
          @functions << tree
        end
      elsif tree.symbol == :binding
        @bindings << tree
      elsif tree.symbol == :struct
        ingest_struct tree
      end
    end
  end

  def function_start(symbol, args, is_closure, restrict_arguments = true, stack_name=nil)
      stack_name = if stack_name
                     stack_name
                   else
                     is_closure ? "closure" : symbol.to_s
                   end
      [
        "func ",
        is_closure ? "" : hzl_namespace(symbol),
        "(arguments []*any, hzl_yield block) *any {\n",
        restrict_arguments ? "if len(arguments) != #{args.length} {
          panic(\"Wrong number of arguments for #{symbol} - not #{args.length}\")
        }\n" : "",
        "
        defer func() {
          err := recover()
          if err != nil {
            call_stack = append(call_stack, \"#{stack_name}\")
            panic(err)
          }
        }()
        ",
      ].join
  end

  def function_end()
    "}"
  end

  def generate_function(symbol, args, forest, is_closure = false, extra="", stack_name=nil)

    restrict_arguments = true

      defined_arguments = args.each_with_index.map do |a, i|
        raise "arguments to a function definition must be idents" unless a.is_a?(Token) or a.is_ident?
        rv = if a.symbol.to_s[0] == "*"
          raise "splat must be last argument" unless i == args.length - 1
          restrict_arguments = false

          a.symbol = a.symbol.to_s[1..-1].to_sym
          temp = temp_var
          "
          #{temp} := arguments[#{i}:]
          #{hzl_namespace(a.symbol)} := into_any(ARRAY, unsafe.Pointer(&#{temp}));"
        else
          "#{hzl_namespace(a.symbol)} := arguments[#{i}];"
        end
        stack_push a

        rv
      end

      # Function start could be done so much better.
      start = function_start(symbol, args, is_closure, restrict_arguments, stack_name)

      [
        start,
        defined_arguments,
        extra,
        generate_calls(forest),
        function_end,
        is_closure ? "" : "\n\n",
      ].join
  end

  def generate_binding(tree)
    raise "binding takes two arguments" unless tree.arguments.length == 2
    raise "binding takes a block" unless tree.block
    unless tree.block.arguments.length.even?
      raise "binding's block takes an even number of arguments"
    end
    unless (tree.block.forest.length == 2 and
            tree.block.forest[0].is_string? and
            tree.block.forest[1].is_string?)
      raise "binding's block takes exactly two strings"
    end
    fn_name = tree.arguments[0].symbol
    fn_type = tree.arguments[1].symbol
    arg_names = tree.block.arguments.each_slice(2).map { |a, b| a }
    start = function_start(fn_name, arg_names, false)

    type_arguments = tree.block.arguments.each_slice(2).with_index.map { |args, i|
      name, type = args
      if type.symbol == :any
         "\n#{name.symbol} := arguments[#{i}]\n"
      else
        "
        if arguments[#{i}].hazelnut_type != #{TYPE_MAPPING[type.symbol]} {
           panic(\"#{i}th argument of #{fn_name} takes a #{type.symbol}\")
         }
         #{name.symbol} := (*#{GO_OUTPUT_MAPPING[type.symbol] or type.symbol})(arguments[#{i}].hazelnut_data)
        " # These arguments are not hzl_namespace'd
      end
    }
    preceeding, return_value = tree.block.forest

    return_value = if fn_type == :any
      "return #{unescape(return_value)}"
    else
      "
        return into_any(#{TYPE_MAPPING[fn_type]}, unsafe.Pointer(#{unescape(return_value)}))
      "
    end

    [
      start,
      type_arguments,
      unescape(preceeding),
      return_value,
      function_end,
    ].join
  end

  def generate_headers
    "package main\n" +
    @functions.map do |tree|
      function_name = tree.arguments.shift
      unless function_name and function_name.is_ident?
        raise "first argument to define must be an ident"
      end
      raise "define takes a block" unless tree.block
      raise "define doesn't take any arguments" if tree.arguments and not tree.arguments.empty?
      enter_stack
      output = generate_function(function_name.symbol, tree.block.arguments, tree.block.forest) 
      exit_stack
      output
    end.join("\n") +
    @bindings.map { |tree| generate_binding tree }.join("\n") +
    struct_headers + 
    call_stack +
    init_function
  end

  def call_stack
    "
    var call_stack []string
    "
  end

  def init_function
    [
      "func init() {\n",
      struct_init,
      "}\n",
    ].join
  end

  def generate_main
    [
      '
      func main() {
        defer func() {
          err := recover()
          if err != nil {
            fmt.Printf("\n\n!! panic !!\n")
            for i := len(call_stack)-1; i >= 0; i--{
              call := call_stack[i]
              if i < 15 {
                fmt.Printf("within %s\n", call)
              }
            }
            fmt.Printf("%s\n", err)
          }
        }()

      ',
      generate_calls(@forest, false),
      "
      }
      ",
    ].join
  end

  def generate_calls(forest, includereturn = true)
    forest.map! { |tree| fn = call(tree) }

    if includereturn
      ret = forest[-1]
     # Not sure if this is necessary
      if ret.return_value != ret.body
        ret.prerequisites += ret.body
        ret.body = ret.return_value
      end
      ret.body = "return " + ret.body
    end
    forest.map! { |fn| [fn.prerequisites, fn.body] }.join(';')
  end

end

def unescape(expression)
  code = expression.symbol.to_s[1..-2]
  code.gsub "\\\\", "\\"
  code.gsub "\\\"", "\""
end

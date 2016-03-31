# tests.rb

require 'shindo'
require 'pry'

require_relative 'data.rb'
require_relative 'token.rb'
require_relative 'parser.rb'
require_relative 'generator.rb'


# Just to make comparisons & literals easier.
class Expression

  def to_array
    if (not self.block or self.block.forest.length == 0) \
       and (not self.arguments or self.arguments.length == 0)
      return self.symbol
    end
    b = self.block ? {self.block.arguments.map { |x| x.symbol } => self.block.forest.map { |x| x.to_array }} : {}
    a = self.arguments ? self.arguments.map { |x| x.to_array } : []

    [self.symbol, a, b]
  end

end

class Generator
  def self.reset
    @@stacks = [[]]
  end
end

class Printer
  attr_accessor :str
  def initialize(str)
    @str = str
  end

  def inspect
    @str.inspect + "\n" + @str
  end

  def ==(other)
    str == other.str
  end
end


class Tokenizee
  attr_accessor :tokens
end

Shindo.tests("Tokenizer") do

  def token_test(text, return_value)
    n = nil
    if return_value.is_a? Array
      n = return_value.length
      return_value.map! { |x| (x.is_a? Symbol) ? x.to_sym : x }
      return_value = [n, *return_value]
    else
      n = 1
      unless return_value.is_a? Symbol
        return_value = return_value.to_sym
      end
      return_value = [n, return_value]
    end
    returns(return_value) do
      t = Tokenizer.new text
      t.read
      return_values = t.tokens.map { |token| token.symbol }
      n = t.tokens.length
      if return_values.is_a? Array
        [n, *return_values]
      else
        [n, return_values]
      end
    end
  end

  # test number
  token_test "1234.434", :"1234.434"

  # test ident
  token_test "abcd", :abcd

  # test ident and number
  token_test "abcd 123", [:abcd, :"123"]

  # test ident with number
  token_test "abc23d 123", [:abc23d, :"123"]

  # test ident with number
  token_test "abc23d 123", [:abc23d, :"123"]

  # test punctuation with characters
  # Might want to change this:
  token_test "Hello$text", [:"Hello$text"]

  token_test "Hello.text", [:"Hello", :".text"]

  token_test ".= Hello text", [:".=", :Hello, :text]

  token_test "{ interesting }", [:do, :interesting, :end]

  token_test "interesting_tidbit", [:interesting_tidbit]

  token_test "interesting-tidbit", [:"interesting-tidbit"]

  token_test "'quote1'", [:"'quote1'"]

  token_test '"quote2"', [:'"quote2"']

  token_test '"quote3\\""', [:'"quote3\\""']

  token_test "'quote4\\''", [:"'quote4''"]

  token_test '"quote"
              \'quote\'', [:'"quote"', :"\n", :"'quote'"]

  # test some real code
  token_test "class Hello do
      some hi, there
    end",
    [:class, :Hello, :do, :"\n", :some, :hi, :there, :"\n", :end]


end

Shindo.tests("Parser") do

  def parses_test(string, arrays)
    returns(arrays, string) do
      t = Tokenizer.new string
      t.read
      parser = Parser.new t.tokens
      a = parser.parse.map { |x| x.to_array }
      a
    end
  end


  parses_test "map", [:map]

  parses_test "map a b", [[:map, [:a, :b], {}]]

  parses_test "map {\nb }", [[:map, [], {[] => [:b]}]]

  parses_test "map a {;b }", [[:map, [:a], {[] => [:b]}]]

  parses_test "map a (lambda {x: b x })", [[:map, [:a, [:lambda, [], { [:x] => [[:b, [:x], {}]]}]], {}]]

  parses_test "hi there; wonderkin", [[:hi, [:there], {}], :wonderkin]

  parses_test "hi there\n wonderkin", [[:hi, [:there], {}], :wonderkin]

  parses_test "hi there\n wonderkin = 2", [[:hi, [:there], {}], [:"=", [:'2', :wonderkin], {}]]

  parses_test "hi there {\nwonderkin}", [[:hi, [:there], {[] => [:wonderkin]}]]

  parses_test "\tif {\n\t\tprint this\n\t}", [[:if, [], {[] => [[:print, [:this], {}]]}]]

  parses_test "let (hi 3) 4", [[:let, [[:hi, [:"3"], {}], :"4"], {}]]

  parses_test "[one two three]", [[:list, [:one, :two, :three], {}]]

  # Operators

  parses_test "2 + 2", [[:+, [:"2", :"2"], {}]]

  parses_test "(+ 3 2)", [[:+, [:"3", :"2"], {}]]

  parses_test "function a + b", [[:+, [:b, [:function, [:a], {}]], {}]]
  parses_test "function (a == b)", [[:function, [[:==, [:b, :a], {}]], {}]]

  parses_test "function (length a == b)", [[:function, [[:==, [:b, [:length, [:a], {}]], {}]], {}]]

  parses_test "1 + 2 * 3", [[:+, [[:*, [:"3", :"2"], {}], :"1"], {}]]

  parses_test "3 * 2 + 1", [[:+, [:"1", [:*, [:"2", :"3"], {}]], {}]]

  parses_test "1 * (2 + 3)", [[:*, [[:+, [:"3", :"2"], {}], :"1"], {}]]

  parses_test "(2 + 3) * 1", [[:*, [:"1", [:+, [:"3", :"2"], {}]], {}]]

  # Dot syntax

  parses_test "map.test", [[:".", [:map, :'"test"'], {}]]

  parses_test "map.test a b", [[:".", [:map, :'"test"', :a, :b], {}]]

  parses_test "map a.test b", [[:"map", [[:'.', [:a, :'"test"'], {}], :b], {}]]

  parses_test "all.map a.test b", [[:".", [:all, :'"map"', [:'.', [:a, :'"test"'], {}], :b], {}]]

  # Regression Tests

  parses_test "plum ((pear mate)) next ", [[:plum, [[:pear, [:mate], {}], :"next"], {}]]

  parses_test "puts (something)\n else", [[:puts, [:something], {}], :else]

end

Shindo.tests("Generator") do

  def generates_test(description, hazelnut_code, go_code)
    File.write("/tmp/hazelnut2", go_code.strip)
    `goimports -w /tmp/hazelnut2`
    go_code= `gofmt -s /tmp/hazelnut2`.gsub "\t", "  "
    returns(Printer.new(go_code), description) do
      t = Tokenizer.new hazelnut_code

      t.read
      parser = Parser.new t.tokens
      forest = parser.parse
      Generator.reset
      generator = Generator.new forest
      output = generator.generate.gsub(/hazelnut_(\d)*/, "temp")
      Printer.new(output)
    end
  end

  generates_test  "function call with arguments",
  "call something", '
    package main

    var struct_definitions []definition

    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}}
    }

    func main() {
      hzl_call([]*any{hzl_something([]*any{}, nil)}, nil)
    }
  '

  generates_test "function call with block",
  "map a { c : d c }", '
    package main

    var struct_definitions []definition

    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}}
    }

    func main() {
      hzl_map([]*any{hzl_a([]*any{}, nil)}, func (arguments []*any, hzl_yield block) *any {
        if len(arguments) != 1 {
          panic("Wrong number of arguments for  - not 1")
        }
        hzl_c := arguments[0];
        return hzl_d([]*any{hzl_c}, nil)
      })
    }
  '

  generates_test "if and else statement",
  "
    if a {
      b
    } else {
      c
    }
  ", '
    package main

    var struct_definitions []definition

    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}}
    }

    func main() {
      if from_bool(hzl_a([]*any{}, nil)) {
        hzl_b([]*any{}, nil)
      } else {
        hzl_c([]*any{}, nil)
      }
    }
  '

  generates_test "= syntax",
  "
    a = 2
    b a
  ", '
    package main

    import "unsafe"

    var struct_definitions []definition

    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}}
    }

    func main() {
      temp := 2
      hzl_a := into_any(INT, unsafe.Pointer(&temp))
      hzl_b([]*any{hzl_a}, nil)
    }
  '

  generates_test "string constant",
  "
    a = 'testing'
    puts a
  ", '
    package main

    import "unsafe"

    var struct_definitions []definition

    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}}
    }

    func main() {
      temp := "testing"
      hzl_a := into_any(STRING, unsafe.Pointer(&temp))
      hzl_puts([]*any{hzl_a}, nil)
    }
  '

  generates_test "array constant",
  "
    a = list 2 'five'
    puts a
  ", '
    package main

    import "unsafe"

    var struct_definitions []definition


    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}}
    }

    func main() {
      temp := 2
      temp := "five"

      temp := []*any{into_any(INT, unsafe.Pointer(&temp)), into_any(STRING, unsafe.Pointer(&temp))}
      hzl_a := into_any(ARRAY, unsafe.Pointer(&temp))
      hzl_puts([]*any{hzl_a}, nil)
    }
  '

  generates_test "define a struct",
  "
    struct animal do
      width
      color
    end

    struct hat do
      brimmed
      color
    end

    myhat = new hat
    myhat.width = 4
    puts myhat.width
  ", '
    package main

    import "unsafe"

    var struct_definitions []definition

    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}, definition{name: "animal", members: []string{"width", "color"}, methods: []method{}},
        definition{name: "hat", members: []string{"brimmed", "color"}, methods: []method{}}}
    }

    func main() {
      temp := []*any{into_any(NIL, nil), into_any(NIL, nil)}
      hzl_myhat := into_any(7, unsafe.Pointer(&temp))
      temp := "width"
      temp := 4
      hzl____dot______equals___([]*any{hzl_myhat, into_any(STRING, unsafe.Pointer(&temp)), into_any(INT, unsafe.Pointer(&temp))}, nil)
      temp := "width"
      hzl_puts([]*any{hzl____dot___([]*any{hzl_myhat, into_any(STRING, unsafe.Pointer(&temp))}, nil)}, nil)
    }
  '

  generates_test "define a function",
  "
    define a do b
      print
    end
    a b
  ", '
    package main

    func hzl_a(arguments []*any, hzl_yield block) *any {
        if len(arguments) != 1 {
          panic("Wrong number of arguments for a - not 1")
        }
        hzl_b := arguments[0]
      return hzl_print([]*any{}, nil)
    }

    var struct_definitions []definition

    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}}
    }

    func main() {
      hzl_a([]*any{hzl_b([]*any{}, nil)}, nil)
    }
  '

  generates_test "define a struct and method",
    "
      struct animal {
        position
      }
      define animal.walk { x
        self.position = self.position + x
      }

      animal.walk 3
    ",
    '
		package main

		import "unsafe"

		var struct_definitions []definition

    func init() {
      struct_definitions = []definition{definition{name: "int", members: []string{}, methods: []method{}},
        definition{name: "float32", members: []string{}, methods: []method{}},
        definition{name: "string", members: []string{}, methods: []method{}},
        definition{name: "nil", members: []string{}, methods: []method{}},
        definition{name: "bool", members: []string{}, methods: []method{}},
        definition{name: "array", members: []string{}, methods: []method{}}, definition{name: "animal", members: []string{"position"}, methods: []method{{"walk", func(arguments []*any, hzl_yield block) *any {
          if len(arguments) != 2 {
            panic("Wrong number of arguments for  - not 2")
          }
          hzl_self := arguments[0]
          hzl_x := arguments[1]
          _ = hzl_self
          temp := "position"
          temp := "position"
          return hzl____dot______equals___([]*any{hzl_self, into_any(STRING, unsafe.Pointer(&temp)), hzl____plus___([]*any{hzl_x, hzl____dot___([]*any{hzl_self, into_any(STRING, unsafe.Pointer(&temp))}, nil)}, nil)}, nil)
        }}}}}
    }

		func main() {
			temp := "walk"
			temp := 3
			hzl____dot___([]*any{hzl_animal([]*any{}, nil), into_any(STRING, unsafe.Pointer(&temp)), into_any(INT, unsafe.Pointer(&temp))}, nil)
		}
    '

  returns(false, "outputs valid gofmt") do
    t = Tokenizer.new "

    test test
    mapped a {b c : c} test
    if hi {
      print this
    } else {
      print that
    }
    hi = this that wow
    hi = 2

    map {
      next = hi
    }

    define hi do this that
      somefunction this that
    end

    struct test do
      hi
    end

    define test.wow do y
      puts (2 * x)
    end

    test.wow 4
    "
    t.read
    parser = Parser.new t.tokens
    forest = parser.parse
    generator = Generator.new forest
    output = generator.generate
    output.empty?
  end

end

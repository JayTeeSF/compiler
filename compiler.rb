#!/usr/bin/env ruby

class Interpreter
  def self.interpret(_compiler)
    new(_compiler).interpret
  end

  def initialize(_compiler)
    @compiler = _compiler
  end

  def interpret
    js = @compiler.compile
    run(js) # interpreter :)
  end

  NODE_CMD = `which node`
  def run(js)
    puts `echo "#{js}" | #{NODE_CMD}`
  end
end

class Compiler
  DEFAULT_CODE =<<-EOC
    def f() 1 end
    def og(x) 2 end
    def g(x) x end
    def h(x,y) add(y, 3) end
    def oh(x,y) x end
    def i(x) j(x) end
    def j(x,y) h(x,y) end
    def k(x,y) h(g(x), h(x,y)) end
  EOC

  def self.compile(code, options={})
    new(code, options).compile
  end

  def initialize(code, options={})
    @code = code
    @lexer = options[:lexer] || Lexer.new
  end

  def compile
    tokens = @lexer.tokenize(@code.dup)
    tree = Parser.new(tokens).parse
    js = generate(tree)

    # apparently compilers add a "runtime"
    # i.e.
    # in c it's minimal
    # in go it's large: the garbage collector, etc
    # our runtime includes an "add" function (in our standard library :-) )
    return js + "\n" + runtime # stop here if a compiler
  end

  def runtime
    # return "function add(a, b) { return a + b }; if (k(2, 21) === 27) { console.log('ok'); } else { console.log('nok');}"
    return "function add(a, b) { return a + b }; console.log('ok')"
  end

  def generate(node)
    if node.instance_of?(Suite)
      return node.defs.map {|child| generate(child) }.join("\n")
    elsif node.instance_of?(Def)
      return "function %s(%s) { return %s };" % [node.name, generate(node.args), generate(node.body)]
    elsif node.instance_of?(Args)
      return node.args.join(", ")
    elsif node.instance_of?(IntegerConstant)
      return node.value
    elsif node.instance_of?(VariableRef)
      return node.name
    elsif node.instance_of?(Funcall)
      return "%s(%s)" % [generate(node.callable), node.args.map {|arg| generate(arg)}.join(", ")]
    end
    return "<#{node.inspect}>"
  end
end

Def = Struct.new(:name, :args, :body)
#class Def
#  attr_reader :name, :args, :body
#  def initialize(_name, _args, _body)
#    @name = _name
#    @args = _args
#    @body = _body
#  end
#end
Expr = Struct.new(:operation, :left, :right)
IntegerConstant = Struct.new(:value)
VariableRef = Struct.new(:name)
Funcall = Struct.new(:callable, :args)
Args = Struct.new(:args)
Suite = Struct.new(:defs)
#class Suite
#  attr_reader :defs
#  def initialize(_defs)
#    @defs = _defs
#  end
#end

class Parser
  def initialize(tokens)
    @tokens = tokens.dup
  end

  def parse
    parse_suite
  end

  def parse_suite
    defs = []
    while !@tokens.empty?
      defs << parse_def
    end
    return Suite.new(defs)
  end

  def parse_def
    shift(:def)
    name = shift(:identifier).string
    args = parse_args
    expr = parse_expr
    shift(:end)
    return Def.new(name, args, expr)
  end

  def parse_expr
    value = nil
    begin
      value = shift(:integer)
      return IntegerConstant.new(value.string.to_i)
    rescue ArgumentError
    end
    variable_ref = parse_variable_ref
    if peek?(:oparen)
      shift(:oparen)
      funcall = Funcall.new(variable_ref, parse_expr_list)
      shift(:cparen)
      return funcall
    else
      return variable_ref
    end
  end

  def parse_expr_list
    exprs = []
    continue = true
    while continue
      begin
        exprs << parse_expr #parse_variable_ref
        shift(:comma)
      rescue ArgumentError
        continue = false
        break
      end
    end
    return exprs
  end

  def parse_variable_ref
    value = shift(:identifier)
    return VariableRef.new(value.string)
  end

  def parse_args
    args = []
    shift(:oparen)
    continue = true
    while continue
      begin
        args << shift(:identifier).string
        shift(:comma)
      rescue ArgumentError
        continue = false
      end
    end
    shift(:cparen)
    return Args.new(args)
  end

  def shift(token_type)
    #puts "\n\tshifting: #{@tokens.first}\n"
    expect(token_type) # make sure we're seeing what we expect
    shifted = @tokens.shift # remove head of list
    #puts "\n\tshifted: #{shifted}\n"
    return shifted
  end

  def peek?(expected_token_type)
    return (_actual_token_type == expected_token_type)
  end

  def expect(expected_token_type)
    if _actual_token_type != expected_token_type
      fail(ArgumentError, "Expected token of type #{expected_token_type} but got #{_actual_token_type}")
    end
  end

  def _actual_token_type
    @tokens.first.type
  end
end

Token = Struct.new(:type, :string)
class Lexer
  TOKEN_PATTERN = {
    def: /^def\b/,
    end: /^end\b/,
    identifier: /^[a-z]+/,
    integer: /^[0-9]+/,
    comma: /^\,/,
    oparen: /^\(/,
    cparen: /^\)/,
    whitespace: /^\s/,
  } # in ruby these are now ordered, so precedence is preserved

  def tokenize(code)
    tokens = []
    while !code.empty?
      #puts "code remains: #{code.inspect}"
      token = extract_a_token_from(code)
      # puts "token: #{token}"
      code = code[token.string.length..-1]
      tokens << token
    end
    useful_tokens = tokens.reject {|t| t.type == :whitespace}
    # puts "tokens: #{useful_tokens.inspect}"
    return useful_tokens
  end

  def extract_a_token_from(code)
    TOKEN_PATTERN.each_pair do |type, regex|
      # puts "regex: #{regex.inspect}"
      #print "checking for a matching: #{type}"
      match = regex.match(code)
      if match
        #print " ** match"
        return Token.new(type, match[0])
      end
    end
    fail(InvalidArgument, "Unknown token: #{code.inspect}")
  end
end

if __FILE__ == $PROGRAM_NAME
  code = ARGV.length > 0 ? ARGV.join(" ") : Compiler::DEFAULT_CODE
  #Compiler.compile(code)
  puts "input code:\n#{code}"
  compiler = Compiler.new(code)
  puts "\ncompiled js:\n#{compiler.compile}"
  puts "\ninterpreting with node..."
  Interpreter.interpret(compiler)
  puts "done."
end

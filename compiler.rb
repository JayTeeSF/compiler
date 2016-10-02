#!/usr/bin/env ruby

class Compiler
  DEFAULT_CODE =<<-EOC
    def f() 1 end
    def g(x) 1 end
    def h(x,y) 1 end
    def i(x) j(x) end
    def j(x,y) h(x,y) end
    def k(x,y) h(g(x), h(x,y)) end
  EOC

  TOKEN_PATTERN = {
    def: /^def\b/,
    end: /^end\b/,
    identifier: /^[a-z]+/,
    integers: /^[0-9]+/,
    comma: /^\,/,
    oparen: /^\(/,
    cparen: /^\)/,
    whitespace: /^\s/,
  }

  def self.compile(code, options={})
    new(code, options).compile
  end

  def initialize(code, options={})
    @code = code
    @lexer = options[:lexer] || Lexer.new
  end

  def compile
    @lexer.tokenize(@code.dup)
  end

  Token = Struct.new(:type, :string)

  class Lexer
    def tokenize(code)
      while !code.empty?
        #puts "code remains: #{code.inspect}"
        token = extract_a_token_from(code)
        puts "token: #{token}"
        code = code[token.string.length..-1]
      end
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
        fail("Unknown token: #{code.inspect}")
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  code = ARGV.length > 0 ? ARGV.join(" ") : Compiler::DEFAULT_CODE
  Compiler.compile(code)
end

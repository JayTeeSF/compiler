#!/usr/bin/env ruby

# convert this to lambda calc
# meaning: only accept one arg:
# x = lambda{|x| h(g(f(x)) }
def orig(n)
  if 0 == n
    return 1
  else
    return n * orig(n - 1)
  end
end

### START:

NULL = lambda { |x| x }

MTRUE = lambda { |t| lambda { |f| t[NULL] }}
MFALSE = lambda { |t| lambda { |f| f[NULL] }}

# ONE = 1 # no #1 in lambda calculus
#
# Alonzo Church, created church numerals
# Related to piano arithmetic:
ZERO = lambda { |f| lambda{ |x| x }}

# identity and successor functions:
#IDENTITY = lambda {|n| n }
IDENTITY = lambda {|n| lambda { |f| lambda { |x| n[f][x]  }}}
S = lambda {|n| lambda { |f| lambda { |x| f[ n[f][x]]  }}}
ADD1 = S
ADD = lambda {|n| lambda{|m| n[ADD1][m] }}

ONE = ADD1[ZERO]
TWO = ADD1[ONE]
# THREE = lambda { |f| lambda{ |x| f[f[f[x]]] }}
THREE = ADD1[TWO]

#IS_ZERO = lambda {|x| x == 0 }
#
IS_ZERO = lambda { |n| n[lambda{|x| MFALSE}][MTRUE] }

#SUB1 = lambda {|x| x - 1 }
#
SUB1 = lambda { |n|
  lambda { |f|
    lambda { |x|
      n[ lambda { |g| lambda { |h| h[g[f]] }}][
        lambda { |u| x }
      ][
        lambda { |u| u }
      ]
    }
  }
}

# MULT = lambda {|x, y| x * y }
#MULT = lambda {|x| lambda {|y| x * y} }
#
# Add m to zero n times
MULT = lambda {|n| lambda {|m| n[lambda { |x| ADD[x][m]}][ZERO]  }}

SIX = ADD[THREE][THREE]

# IF = lambda {|x, y, z| x ? y.call : z.call }
# IF = lambda {|x| lambda { |y| lambda {|z| x ? y[nil] : z[nil] }}}
#
IF = lambda { |cond| lambda { |t| lambda { |f| cond[t][f] }}}


# Convert them to Ruby #'s in the following way:
# puts TWO[lambda{|x| x + 1}][0]
# puts THREE[lambda{|x| x + 1}][0]


#puts IDENTITY[THREE][lambda{|x| x + 1}][0] # 3
#puts S[THREE][lambda{|x| x + 1}][0] # 4
#puts ADD[THREE][TWO][lambda{|x| x + 1}][0] # 5
#puts MULT[THREE][TWO][lambda{|x| x + 1}][0] # 6
#puts SUB1[THREE][lambda{|x| x + 1}][0] # 2
#puts IDENTITY[SIX][lambda{|x| x + 1}][0] # 6

# manually y-combinated below...
#fact = lambda { |myself|
#  lambda { |n|
#    IF[
#      IS_ZERO[n] # condition
#    ][
#      lambda { |_| ONE } # true case
#    ][
#      lambda { |_| MULT[n][ myself[myself][SUB1[n]]] } # false case
#    ]
#  }
#}

if __FILE__ == $PROGRAM_NAME
  puts(
    lambda { |myself|
      lambda { |n|
        IF[
          IS_ZERO[n] # condition
        ][
          lambda { |_| ONE } # true case
        ][
          lambda { |_| MULT[n][ myself[myself][SUB1[n]]] } # false case
        ]
      }
    }[
      lambda { |myself|
        lambda { |n|
          IF[
            IS_ZERO[n] # condition
          ][
            lambda { |_| ONE } # true case
          ][
            lambda { |_| MULT[n][ myself[myself][SUB1[n]]] } # false case
          ]
        }
      # }][6] <-- no good, need lambda number
      }][SIX][
    lambda { |x| x + 1}][0]
    #lambda { |x| x + "X"}][""]
    #lambda { |x| x + [1]}][[]]
  )
end

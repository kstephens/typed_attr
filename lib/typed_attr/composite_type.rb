class Module
  class CompositeType < self
    CACHE = { }
    def self.new_cached *args
      CACHE[[ self, args ]] ||= new(*args)
    end
    def initialize *t
      @_t = t
    end
    attr_reader :_t
  end

  class ContainerType < CompositeType
    def === x
      @_t[0] === x and x.all?{|e| @_t[1] === e }
    end
    def to_s
      @to_s ||= "#{@_t[0]}.of(#{@_t[1]})".freeze
    end
  end

  # Constructs a type of Enumeration of an element type.
  #
  # Array.of(String)
  def of t
    ContainerType.new_cached(self, t)
  end

  class PairType < CompositeType
    def === x
      Enumerable === x and @_t[0] === x[0] and @_t[1] === x[1]
    end
    def to_s
      @to_s ||= "#{@_t[0]}.with(#{@_t[1]})".freeze
    end
  end

  # Constructs a type of Pairs.
  #
  # Hash.of(String.with(Integer))
  def with t
    PairType.new_cached(self, t)
  end

  class DisjunctiveType < CompositeType
    def === x
       @_t[0] === x or @_t[1] === x
    end
    def to_s
      @to_s ||= "(#{@_t[0]}|#{@_t[1]})".freeze
    end
  end

  # Constructs a type which can be A OR B.
  #
  # Array.of(String|Integer)
  def | t
    DisjunctiveType.new_cached(self, t)
  end

  class ConjunctiveType < CompositeType
    def === x
       @_t[0] === x and @_t[1] === x
    end
    def to_s
      @to_s ||= "(#{@_t[0]}&#{@_t[1]})".freeze
    end
  end

  # Constructs a type which must be A AND B.
  #
  # Array.of(Positive&Integer)
  def & t
    ConjunctiveType.new_cached(self, t)
  end

  class NegativeType < CompositeType
    def === x
       ! (@_t[0] === x)
    end
    def to_s
      @to_s ||= "(~#{@_t[0]})".freeze
    end
  end

  # Constructs a type which must not be A.
  #
  # Array.of(~NilClass)
  def ~@
    case self
    when NegativeType
      self._t.first
    else
      NegativeType.new_cached(self)
    end
  end
end

# Numeric origin/continuum types.

# Objects that are Numeric or respond to :to_numeric.
module Numericlike
  def self.=== x
    case
    when Numeric === x
      x
    when x.respond_to?(:to_numeric)
      x.to_numeric
    end
  end
end

# Objects that are Numericlike and > 0.
module Positive
  def self.=== x
    n = Numericlike === x and n > 0
  end
end

# Objects that are Numericlike and < 0.
module Negative
  def self.=== x
    n = Numericlike === x and n < 0
  end
end

# Objects that are Numericlike and <= 0.
module NonPositive
  def self.=== x
    n = Numericlike === x and n <= 0
  end
end

# Objects that are Numericlike and >= 0.
module NonNegative
  def self.=== x
    n = Numericlike === x and n >= 0
  end
end

# Objects that can do IO.
#
# Note: IO and StringIO do not share a common ancestor Module
# that distingushes them as being capable of "IO".
# So we create one here -- devdriven.com 2013/11/14
require 'stringio'
module IOable
  ::IO.send(:include, self)
  ::StringIO.send(:include, self)
end

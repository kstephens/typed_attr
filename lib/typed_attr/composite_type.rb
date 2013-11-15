class Module
  class CompositeType < self
    def initialize a, b
      @a = a
      @b = b
    end
    def to_s
      @to_s ||= "#{@a}.#{op}(#{@b})".freeze
    end
  end

  class ContainerType < CompositeType
    def === x
      @a === x and x.all?{|e| @b === e }
    end
    def op; 'of'; end
  end

  # Constructs a type of Enumeration of an element type.
  #
  # Array.of(String)
  def of t
    ContainerType.new(self, t)
  end

  class PairType < CompositeType
    def === x
      Enumerable === x and @a === x[0] and @b === x[1]
    end
    def op; 'with'; end
  end

  # Constructs a type of Pairs.
  #
  # Hash.of(String.with(Integer))
  def with t
    PairType.new(self, t)
  end

  class AlternateType < CompositeType
    def === x
       @a === x or @b === x
    end
    def to_s
      @to_s ||= "#{@a}|#{@b}".freeze
    end
  end

  # Constructs a type of Pairs.
  #
  # Array.of(String|Integer)
  def | t
    AlternateType.new(self, t)
  end
end


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

module Positive
  def self.=== x
    n = Numericlike === x and n > 0
  end
end

module Negative
  def self.=== x
    n = Numericlike === x and n < 0
  end
end

# Note: IO and StringIO do not share a common ancestor Module
# that distingushes them as being capable of "IO".
# So we create one here -- devdriven.com 2013/11/14
require 'stringio'
module IOable
  ::IO.send(:include, self)
  ::StringIO.send(:include, self)
end

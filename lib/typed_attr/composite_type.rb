require 'thread'

class Module
  class CompositeType < self
    class Error < ::StandardError; end

    def self.new_cached *types
      key = [ self, types ]
      (Thread.current[:'Module::CompositeType.cache'] ||= { })[key] ||=
      CACHE_MUTEX.synchronize do
        CACHE[key] ||= new(types)
      end
    end
    CACHE = { }
    CACHE_MUTEX = Mutex.new

    def initialize types
      raise Error, "cannot create CompositeType from unamed object" unless types.all?{|x| x.name}
      @_t = types
    end
    attr_reader :_t
    def name; to_s; end
  end

  # Matches nothing.
  module Void
    def === x
      false
    end
  end

  class ContainerType < CompositeType
    def === x
      @_t[0] === x and x.all?{|e| @_t[1] === e }
    end
    def to_s
      @to_s ||= "#{@_t[0]}.of(#{@_t[1]})".freeze
    end
  end

  # Constructs a type of that matches an Enumerable with an element type.
  #
  # Array.of(String)
  def of t
    ContainerType.new_cached(self, t)
  end

  class EnumeratedType < CompositeType
    def === x
      Enumerable === x and
        @_t.size == x.size and
        begin
          i = -1
          @_t.all?{|t| t === x[i += 1]}
        end
    end
    def to_s
      @to_s ||= "#{@_t[0]}.with(#{@_t[1..-1] * ','})".freeze
    end
  end

  # Constructs a type of Enumerable elements.
  #
  # String.with(Integer, Float) === [ "foo", 1, 1.2 ]
  # Hash.of(String.with(Integer))
  def with *types
    EnumeratedType.new_cached(self, *types)
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
    case
    when t <= self
      self
    when self <= t
      t
    else
      DisjunctiveType.new_cached(self, t)
    end
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
  # Array.of(Positive & Integer)
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
  # Array.of(~ NilClass)
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

# Objects that are > 0.
module Positive
  def self.=== x
    x > 0 rescue nil
  end
end

# Objects that are < 0.
module Negative
  def self.=== x
    x < 0 rescue nil
  end
end

# Objects that are <= 0.
module NonPositive
  def self.=== x
    x <= 0 rescue nil
  end
end

# Objects that are Numericlike and >= 0.
module NonNegative
  def self.=== x
    x >= 0 rescue nil
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

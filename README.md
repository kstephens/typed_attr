# TypedAttr

Typed Attributes and Composite Types for Functional Programming in Ruby

## Usage

TypedAttr simplifies typed functional programming in Ruby.

The creation of data types is central to functional programming.
Ruby does not enforce any typing of object attributes or method parameters.

TypedAttr introduces a class macro "typed_attr".  It constructs an #initialize method
given a list of attributes and their expected types.

Example:

    require 'typed_attr'
    class Account
      typed_attr name: String, amount: Money
    end
    Account.new("Foo", Money.new(1234))
    Account.new("Foo", 1234) # => raise TypeError

Use "typecheck" to perform checks on values:

    def m x, y
      typecheck x, String
      typecheck y, Positive, Integer
      x * y
    end
    m("string", -1) # => raise TypeError
    m("string", 2)  # => "stringstring"

The type assertions use the #=== matching operator.

Composite Types can be constructed to match deeper data structures:

    h = { "a" => 1, "b" => :symbol }
    typecheck h, Hash.of(String.with(Integer|Symbol))

Defining types through Modules:

    module Even
      def self.=== x
         Integer === x and x.even?
      end
    end
    Array.of(Even) === [ 2, 4, 10 ]

Composite types create dynamic Modules that redefine the #=== pattern matching operator.
Thus composite types can be used in "case when" clauses:

    case h
    when Hash.of(String.with(Users))  ...
    when Hash.of(Symbol.with(Object)) ...
    end

Logical operators: #|, #&, #~ are supported:

    a = [ 1, 2, 3 ]
    typecheck a, Array.of(Positive & Numeric)
    typecheck a, Array.of(~ NilClass)
    
    b = [ 1, -2, 3 ]
    typecheck b, Array.of(Positive & Numeric) # => raise TypeError
    
    c = [ 1, nil, 3 ]
    typecheck c, Array.of(~ NilClass)         # => raise TypeError

Composite types are cached indefinitely, therefore anonymous Modules cannot be composed.

## Installation

Add this line to your application's Gemfile:

    gem 'typed_attr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install typed_attr

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

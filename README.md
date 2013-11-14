# TypedAttr

Typed Attributes and Composite Types for Functional Programming in Ruby

## Installation

Add this line to your application's Gemfile:

    gem 'typed_attr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install typed_attr

## Usage

TypedAttr simplifies typed functional programming in Ruby.

The creation of data types is critical to functional programming.
Ruby does not enforce any typing of object attributes or method parameters.

TypedAttr introduces a class macro "typed_attr".  It constructs an #initialize method
given a list of attributes and their expected types.

Example:

    require 'typed_attr'
    class Account
      typed_attr name: String, amount: Money
    end
    Account.new("Foo", Money.new(1234))

Methods can use "typecheck" to perform checks on arguments:

    def m x, y
      typecheck x, Positive, Integer
      typecheck y, String
      y * x
    end
    m(-1, "string") # => raise TypeError
    m(2, "string")  # => "stringstring"

The type assertions use the #=== matching operator.

Composite Types can be constructed to match deeper data structures:

    h = { "a" => 1, "b" => :symbol }
    typecheck h, Hash.of(String.with(Integer|Symbol))

Composite types create dynamic Modules that redefine the #=== pattern matching operator.
Thus composite types can be used in "case when" clauses:

    case h
    when Hash.of(String.with(Users))  ...
    when Hash.of(Symbol.with(Object)) ...
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

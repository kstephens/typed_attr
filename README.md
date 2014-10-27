# CompositeType

Composite Types for Ruby

## Usage

Composite Types can be constructed to match deeper data structures:

    h = { "a" => 1, "b" => :symbol }
    Hash.of(String.with(Integer|Symbol)) === h  # => true

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
    Array.of(Positive & Numeric) === a   # => true
    Array.of(~ NilClass) === a           # => false
    
    b = [ 1, -2, 3 ]
    Array.of(Positive & Numeric) === b   # => false
    
    c = [ 1, nil, 3 ]
    Array.of(~ NilClass) === c           # => false

Composite types are cached indefinitely, therefore anonymous Modules cannot be composed.

See spec/lib/composite_type_spec.rb for more examples.

## Installation

Add this line to your application's Gemfile:

    gem 'composite_type'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install composite_type

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

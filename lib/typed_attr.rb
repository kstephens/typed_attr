require 'typed_attr/enumerable' # map_with_index

  # Typed Attributes.
  module TypedAttr
    def self.included target
      super
      target.extend(ModuleMethods)
    end

    # typecheck value, pattern, ...
    #
    # Check that every pattern === value.
    # Raise TypeError if any do not.
    # Returns value.
    def typecheck value, *checks
      unless checks.all? { | check | check === value }
        raise TypeError, "expected (#{checks * ', '}), given #{value}"
      end
      value
    end

    module ModuleMethods
      OPTIONS = { }
      def typed_attrs_option opts
        OPTIONS.update(opts)
      end

      # typed_attr name: Type, ...
      # typed_attr Type, :name, ...
      #
      # Generates an initialize method that will accept each :name as a typechecked positional argument.
      # Unspecified arguments are undefined and not typechecked.
      # Additional arguments are ignored.
      def typed_attr *types_and_names
        if h = types_and_names.first and Hash === h and types_and_names.size == 1
          names = h.keys
          name_to_type = h
        else
        name_to_type = Hash[*types_and_names.reverse]
        names =
          (0 .. types_and_names.size).to_a.
          keep_if(&:odd?).
          map { | i | types_and_names[i] }
        end
        expr = <<"END"
def initialize *__args
  initialize_typed_attrs *__args
end

def initialize_typed_attrs *__args
  #{names.map_with_index do | name, i |
    "@#{name} = __args[#{i}] if __args.size > #{i}"
  end * "\n  "}
  #{"binding.pry if #{OPTIONS[:pry_if] || true}" if OPTIONS[:pry]}
  #{names.map_with_index do | name, i |
    type = name_to_type[name]
    "typecheck @#{name}, #{type} if __args.size > #{i}"
  end * "\n  "}
end
attr_reader #{names.map(&:to_sym).map(&:inspect) * ', '}
END
        $stderr.puts "#{self}\n#{expr}" if OPTIONS[:debug]
        class_eval expr
      end

      def attrs *args, &blk
        $stderr.puts "  deprecated #{caller[0..2]}"
        typed_attr *args, &blk
      end
    end
  end


# Pollute Object.
Object.send(:include, TypedAttr)

require 'typed_attr/composite_type'

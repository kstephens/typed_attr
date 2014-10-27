require 'spec_helper'
require 'composite_type'

describe Class::CompositeType do
  module A; end
  module B; end
  module C; include A; end
  module D; include B; end
  module E; include A, B; end
  module F; include A, B; end

  it "should cache instances" do
    t1 = Array.of(String.with(~ Float | Symbol & Hash))
    t2 = Array.of(String.with(~ Float | Symbol & Hash))
    expect(t1.object_id) .to eql(t2.object_id)
  end

  it "should fail for anonymous Modules" do
    expect {
      Module.new | String
    }.to raise_error(Module::CompositeType::Error, "cannot create CompositeType from unamed object")
  end

  context Numericlike do
    subject { Numericlike }
    let(:numeric_like) do
      Class.new do
        def to_numeric; -1234; end
      end
    end

    it "should be true for Numeric" do
      v = 1234
      x = subject === v
      expect(x) .to eql(v)
    end

    it "should be true for anything that responds to :to_numeric" do
      v = numeric_like.new
      x = subject === v
      expect(x) .to eql(-1234)
    end

    it "should be false for non-Numeric" do
      v = "a String"
      expect(v.respond_to?(:to_numeric)) .to be_falsey
      expect(subject === v)              .to be_falsey
    end
  end

  context "EnumeratedType" do
    subject { Integer.with(Symbol, String) }
    it "is true for respective unmatches" do
      expect(subject === [ 1, :symbol, "string" ]) .to be_truthy
    end
    it "is false for respective unmatches" do
      expect(subject === [ ]) .to be_falsey
      expect(subject === [ 1, :symbol, :wrong ]) .to be_falsey
    end
    it "is false for too many elements" do
      expect(subject === [ 1, :symbol, "string", :too_many]) .to be_falsey
    end
  end

  context "ContainerType" do
    subject { Array.of(String) }
    it "is true when empty" do
      expect(subject === [ ]) .to be_truthy
    end
    it "is true with a matching element" do
      expect(subject === [ "String" ]) .to be_truthy
    end
    it "is false with an unmatching element" do
      expect(subject === [ "String", 1234 ]) .to be_falsey
    end
    it "is false without an Enumerable" do
      expect(subject === 1234) .to be_falsey
    end
    it "is false when not equvalent" do
      expect(subject === { }) .to be_falsey
    end
  end

  context "EnumeratedType" do
    subject { Hash.of(String.with(Integer)) }
    it "matches" do
      expect(subject === { }) .to be_truthy
      expect(subject === { "foo" => 1 }) .to be_truthy
      expect(subject === { "foo" => :symbol }) .to be_falsey
      expect(subject === { :symbol => 2 }) .to be_falsey
    end
  end

  context "DisjunctiveType" do
    it "matches" do
      expect((String | Integer) === "String") .to be_truthy
      expect((String | Integer) === 1234)     .to be_truthy
      expect((String | Integer) === :symbol)  .to be_falsey
    end

    it "rewrites B | A => A | B" do
      expect((B | A)) .to equal((A | B))
    end

    it "reduces to the greater type if A or B are subclasses of each other" do
      expect(Float   | Numeric) .to equal(Numeric)
      expect(Numeric | Float  ) .to equal(Numeric)
      expect(Numeric | Numeric) .to equal(Numeric)
    end

    it "does not reduce if A and B are disjunctive" do
      expect((Numericlike | Numeric).to_s) .to eq("(Numeric|Numericlike)")
      expect((String | Array).to_s)        .to eq("(Array|String)")
    end
  end

  context "ConjunctiveType" do
    subject { Positive & Integer }
    it "matches" do
      expect(subject === 1) .to be_truthy
      expect(subject === 0) .to be_falsey
      expect(subject === 0.0) .to be_falsey
      expect(subject === :symbol) .to be_falsey
    end
    it "folds A & A => A" do
      expect((A & A)) .to equal(A)
    end
    it "rewrites B & A => A & B" do
      expect((B & A)) .to equal((A & B))
    end
  end

  context "NegativeType" do
    it "matches" do
      expect((~ NilClass) === 1)       .to be_truthy
      expect((~ NilClass) === :symbol) .to be_truthy
      expect((~ NilClass) === nil)     .to be_falsey
    end

    it "rewrites (~ (~ A)) => A" do
      t = String
      expect(~ ~ t) .to equal(t)
    end
  end

  context Negative do
    subject { Negative }
    it "matches non-positive Numerics" do
      expect(subject === -1)   .to be_truthy
      expect(subject === -0.5) .to be_truthy
      expect(subject === 0)    .to be_falsey
      expect(subject === 0.5)  .to be_falsey
      expect(subject === 1)    .to be_falsey
    end
  end

  context Negative do
    subject { Negative }
    it "matches non-positive Numerics" do
      expect(subject === -1)   .to be_truthy
      expect(subject === -0.5) .to be_truthy
      expect(subject === 0)    .to be_falsey
      expect(subject === 0.5)  .to be_falsey
      expect(subject === 1)    .to be_falsey
    end
  end

  context NonPositive do
    subject { NonPositive }
    it "matches non-positive Numerics" do
      expect(subject === -1)   .to be_truthy
      expect(subject === -0.5) .to be_truthy
      expect(subject === 0)    .to be_truthy
      expect(subject === 0.5)  .to be_falsey
      expect(subject === 1)    .to be_falsey
    end
  end

  context NonNegative do
    subject { NonNegative }
    it "matches non-negative Numerics" do
      expect(subject === -1)   .to be_falsey
      expect(subject === -0.5) .to be_falsey
      expect(subject === 0)    .to be_truthy
      expect(subject === 0.5)  .to be_truthy
      expect(subject === 1)    .to be_truthy
    end
  end

  context "#>=" do
    it "returns true where left side is a supertype of right side" do
      expect( Object       >= Module::Void ) .to be_truthy
      expect( Module::Void >= Object       ) .to be_falsey

      expect( Array.of(Object) >= Array.of(String) ) .to be_truthy
      expect( Array.of(String) >= Array.of(Object) ) .to be_falsey
      expect( Array.of(String) >= Object           ) .to be_falsey

      expect( Numeric.with(Integer) >= Numeric.with(Bignum) ) .to be_truthy
      expect( Numeric.with(Integer) >= Float.with(Bignum)   ) .to be_truthy
      expect( Numeric.with(Integer) >= Object.with(Bignum)  ) .to be_falsey
      expect( Numeric.with(Integer) >= Float.with(Object)   ) .to be_falsey
      expect( Numeric.with(Integer) >= Integer.with(Object) ) .to be_falsey

      expect( Hash.of(Symbol.with(Object)) >= Hash.of(Symbol.with(String)) ) .to be_truthy
      expect( Hash.of(Symbol.with(Object)) >= Hash.of(Symbol.with(Fixnum)) ) .to be_truthy
      expect( Hash.of(Symbol.with(String)) >= Hash.of(Symbol.with(Fixnum)) ) .to be_falsey
      expect( Hash.of(Symbol.with(Object)) >= Array.of(String) ) .to be_falsey

      expect( (Integer | Float) >= (Integer | Float) ) .to be_truthy
      expect( (Integer | Float) >= Integer ) .to be_truthy
      expect( (Integer | Float) >= Fixnum  ) .to be_truthy
      expect( (Integer | Float) >= Bignum  ) .to be_truthy
      expect( (Fixnum  | Float) >= Bignum  ) .to be_falsey
      expect( (Fixnum  | Float) >= (Float | Bignum)  ) .to be_falsey
      expect( (Integer | Float) >= (Float | Fixnum)  ) .to be_truthy

      expect( (Positive & Integer) >= (Integer & Positive) ) .to be_truthy
      expect( (A & B) >= E ) .to be_truthy
      expect( (A & B) >= C ) .to be_falsey
      expect( (A & B) >= (E & F) ) .to be_truthy
      expect( (Positive & Integer) >= Integer ) .to be_falsey

      expect( (~ A) >= B ) .to be_falsey
      expect( (~ Numeric) >= (~ Fixnum) )  .to be_falsey
      expect( (~ Fixnum)  >= (~ Numeric) ) .to be_truthy
      expect( (~ Object)  >= (~ Fixnum)  ) .to be_falsey
    end
  end

  context "misc" do
    it "example 1" do
      h = { "a" => 1, "b" => :symbol }
      expect(Hash.of(String.with(Integer | Symbol)) === h) .to be_truthy
    end

    it "example 2" do
      h = { "a" => 1, "b" => "string" }
      expect(Hash.of(String.with(Integer | Symbol)) === h) .to be_falsey
    end

    it "should handle to_s" do
      expect(Hash.of(String.with(Integer | Symbol)).to_s) .to eq("Hash.of(String.with((Integer|Symbol)))")
    end
  end
end

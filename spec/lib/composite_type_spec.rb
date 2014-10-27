require 'spec_helper'
require 'composite_type'

describe Class::CompositeType do
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

  context "Numericlike" do
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
    it "should not fail" do
      expect(subject === [ 1, :symbol, "string" ]) .to be_truthy
    end
    it "should fail" do
      expect(subject === [ ]) .to be_falsey
    end
    it "should fail" do
      expect(subject === [ 1, :symbol, :wrong ]) .to be_falsey
    end
    it "should fail" do
      expect(subject === [ 1, :symbol, "string", :too_many]) .to be_falsey
    end
  end

  context "ContainerType" do
    subject { Array.of(String) }
    it "should not fail when empty" do
      typecheck [ ], subject
    end
    it "should not fail with a matching element" do
      typecheck [ "String" ], subject
    end
    it "should fail when contains unmatching element" do
      expect do
        typecheck [ "String", 1234 ], subject
      end.to raise_error
    end
    it "should fail when is not an Enumerable" do
      expect do
        typecheck 1234, subject
      end.to raise_error
    end
    it "should fail when is not equvalent" do
      expect do
        typecheck({ }, subject)
      end.to raise_error
    end
  end

  context "EnumeratedType" do
    subject { Hash.of(String.with(Integer)) }
    it "should not fail when empty" do
      v = { }
      typecheck v, subject
    end

    it "should not fail" do
      v = { "foo" => 1 }
      typecheck v, subject
    end

    it "should fail" do
      v = { "foo" => :symbol }
      expect(subject === v) .to be_falsey
    end

    it "should fail" do
      v = { :symbol => 2 }
      expect(subject === v) .to be_falsey
    end
  end

  context "DisjunctiveType" do
    it "should reduce to the greater type if A or B are subclasses of each other" do
      expect(Float   | Numeric) .to equal(Numeric)
      expect(Numeric | Float  ) .to equal(Numeric)
      expect(Numeric | Numeric) .to equal(Numeric)
    end

    it "should not reduce if A and B are disjunctive" do
      expect((Numericlike | Numeric).to_s) .to eq("(Numericlike|Numeric)")
      expect((String | Array).to_s)        .to eq("(String|Array)")
    end

    it "should not fail when empty" do
      v = [ ]
      expect(Array.of(String | Integer) === v) .to be_truthy
    end

    it "should not fail" do
      v = [ "String", 1234 ]
      expect(Array.of(String | Integer) === v) .to be_truthy
    end

    it "should fail" do
      v = [ "String", 1234, :symbol ]
      expect(Array.of(String | Integer) === v) .to be_falsey
    end
  end

  context "ConjunctiveType" do
    subject { Array.of(Positive & Integer) }
    it "should not fail when empty" do
      v = [ ]
      expect(subject === v) .to be_truthy
    end

    it "should not fail" do
      v = [ 1, 2 ]
      expect(subject === v) .to be_truthy
    end

    it "should fail" do
      v = [ 0, 1 ]
      expect(subject === v) .to be_falsey
    end

    it "should fail" do
      v = [ 1, :symbol ]
      expect(subject === v) .to be_falsey
    end
  end

  context "NegativeType" do
    it "~~A == A" do
      t = String
      expect(~ ~ t) .to equal(t)
    end

    it "should be true for match" do
      v = [ 1, :symbol ]
      expect(Array.of(~ NilClass) === v) .to be_truthy
    end

    it "should be false for match" do
      v = [ 1, nil, :symbol ]
      expect((~ NilClass) === 1)    .to be_truthy
      expect((~ NilClass) === nil)  .to be_falsey
      expect(Array.of(~ NilClass) === v) .to be_falsey
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

  def typecheck value, type
    raise TypeError, "#{value.inspect} does not match #{type}" unless type === value
  end
end

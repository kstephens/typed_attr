require 'spec_helper'
require 'composite_type'

describe Class::CompositeType do
  it "should cache instances" do
    t1 = Array.of(String.with(~ Float | Symbol & Hash))
    t2 = Array.of(String.with(~ Float | Symbol & Hash))
    t1.object_id.should == t2.object_id
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
      x.should == v
    end

    it "should be true for anything that responds to :to_numeric" do
      v = numeric_like.new
      x = subject === v
      x.should == -1234
    end

    it "should be false for non-Numeric" do
      v = "a String"
      v.respond_to?(:to_numeric).should be_falsey
      (subject === v).should be_falsey
    end
  end

  context "EnumeratedType" do
    subject { Integer.with(Symbol, String) }
    it "should not fail" do
      (subject === [ 1, :symbol, "string" ]).should == true
    end
    it "should fail" do
      (subject === [ ]).should be_falsey
    end
    it "should fail" do
      (subject === [ 1, :symbol, :wrong ]).should be_falsey
    end
    it "should fail" do
      (subject === [ 1, :symbol, "string", :too_many]).should be_falsey
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
      (subject === v).should be_falsey
    end

    it "should fail" do
      v = { :symbol => 2 }
      (subject === v).should be_falsey
    end
  end

  context "DisjunctiveType" do
    it "should reduce to the greater type if A or B are subclasses of each other" do
      (Float   | Numeric).should == Numeric
      (Numeric | Float  ).should == Numeric
      (Numeric | Numeric).should == Numeric
    end

    it "should not reduce if A and B are disjunctive" do
      (Numericlike | Numeric).to_s.should == "(Numericlike|Numeric)"
      (String | Array).to_s.should == "(String|Array)"
    end

    it "should not fail when empty" do
      v = [ ]
      (Array.of(String | Integer) === v).should be_truthy
    end

    it "should not fail" do
      v = [ "String", 1234 ]
      (Array.of(String | Integer) === v).should be_truthy
    end

    it "should fail" do
      v = [ "String", 1234, :symbol ]
      (Array.of(String | Integer) === v).should be_falsey
    end
  end

  context "ConjunctiveType" do
    subject { Array.of(Positive & Integer) }
    it "should not fail when empty" do
      v = [ ]
      (subject === v).should be_truthy
    end

    it "should not fail" do
      v = [ 1, 2 ]
      (subject === v).should be_truthy
    end

    it "should fail" do
      v = [ 0, 1 ]
      (subject === v).should be_falsey
    end

    it "should fail" do
      v = [ 1, :symbol ]
      (subject === v).should be_falsey
    end
  end

  context "NegativeType" do
    it "~~A == A" do
      t = String
      (~ ~ t).should == t
    end

    it "should be true for match" do
      v = [ 1, :symbol ]
      (Array.of(~ NilClass) === v).should be_truthy
    end

    it "should be false for match" do
      v = [ 1, nil, :symbol ]
      ((~ NilClass) === 1)   .should be_truthy
      ((~ NilClass) === nil) .should be_falsey
      (Array.of(~ NilClass) === v).should be_falsey
    end
  end

  context "Positive" do
    it "should be true for Numeric" do
      v = 1234
      (Positive === v).should be_truthy
    end

    it "should be false for negative" do
      v = -1234
      (Positive === v).should be_falsey
    end

    it "should be false for non-Numeric" do
      v = "a String"
      (Positive === v).should be_falsey
    end
  end

  context "Negative" do
    it "should be true for negative Numeric" do
      v = -1234
      (Negative === v).should be_truthy
    end

    it "should be false for positive" do
      v = 1234
      (Negative === v).should be_falsey
    end

    it "should be false for non-Numeric" do
      v = "a String"
      (Negative === v).should be_falsey
    end
  end

  context "misc" do
    it "example 1" do
      h = { "a" => 1, "b" => :symbol }
      typecheck h, Hash.of(String.with(Integer | Symbol))
    end

    it "example 2" do
      h = { "a" => 1, "b" => "string" }
      (Hash.of(String.with(Integer | Symbol)) === h).should be_falsey
    end

    it "should handle to_s" do
      Hash.of(String.with(Integer | Symbol)).to_s.should == "Hash.of(String.with((Integer|Symbol)))"
    end

  end

  def typecheck value, type
    raise TypeError, "#{value.inspect} does not match #{type}" unless type === value
  end
end

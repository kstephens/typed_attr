require 'spec_helper'
require 'typed_attr'

describe TypedAttr do
  context "typecheck" do
    it "should not raise if it does match" do
      typecheck "1234", String
    end

    it "should raise TypeError if it does not match" do
      expect do
        typecheck 1234, String
      end.to raise_error(TypeError)
    end

    it "should handle multiple checks" do
      expect do
        typecheck 1234, Integer, Positive
      end.to_not raise_error

      expect do
        typecheck 1234, Integer, Negative
      end.to raise_error(TypeError)

      expect do
        typecheck 1234, String, Positive
      end.to raise_error(TypeError)
    end
  end

  context "typed_attr" do
    Old = Class.new do
      typed_attr String, :a, Numeric, :b
    end
    New = Class.new do
      typed_attr a: String, b: Numeric
    end

    [ Old, New ].each do | cls |
      context "#{cls} syntax" do
        it "should handle ()" do
          obj = cls.new
          obj.a.should == nil
          obj.b.should == nil
        end

        it "should handle (String)" do
          obj = cls.new("String")
          obj.a.should == "String"
          obj.b.should == nil
        end

        it "should handle (String, Fixnum)" do
          obj = cls.new("String", 123)
          obj.a.should == "String"
          obj.b.should == 123
        end

        it "should handle (String, Fixnum, ANYTHING)" do
          obj = cls.new("String", 123, Object.new)
          obj.a.should == "String"
          obj.b.should == 123
        end
      end
    end
  end
end

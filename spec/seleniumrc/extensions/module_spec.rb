require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Module do
  describe "#deprecate" do
    it "creates a method that calls another method with a deprecation warning" do
      klass = Class.new do
        def car
          :beep
        end
        deprecate :horse, :car
      end
      obj = klass.new
      mock(obj).warn("horse is deprecated. Use car instead.")
      obj.horse.should == :beep
    end

    it "proxies arguments to the new method" do
      klass = Class.new do
        def car(name, location='here')
          "You have a #{name} located at #{location}"
        end
        deprecate :horse, :car
      end
      obj = klass.new
      mock(obj).warn("horse is deprecated. Use car instead.")
      obj.horse('mustang').should == "You have a mustang located at here"
    end
  end
end
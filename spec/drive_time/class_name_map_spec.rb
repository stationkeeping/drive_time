require 'spec_helper'

module DriveTime

  describe ClassNameMap do

    before :each do
      @class_name_map = ClassNameMap.new
      @class_a = "ClassA"
      @class_b = "ClassB"
      @class_c = "ClassC"
      @class_d = "ClassD"
      @class_e = "ClassD"
      @class_name_map.save_mapping(@class_c, @class_d)
    end

    describe "when saving class mapping" do

      context "when no mapped class name is given" do
        it "should return the classname" do
          @class_name_map.save_mapping(@class_a).should == @class_a
        end
      end

      context "when a mapped class name is given" do
        it "should return the mapping" do
          @class_name_map.save_mapping(@class_a, @class_b).should == @class_b
        end
      end

    end

    describe "when resolving the original from mapped" do

      context "when a mapping exists" do

        it "should return the mapping" do
          @class_name_map.save_mapping(@class_a, @class_b)
          @class_name_map.resolve_original_from_mapped(@class_b).should == @class_a
        end

      end

      context "when no mapping exists" do

        it "should return the class" do
          @class_name_map.save_mapping(@class_a)
          @class_name_map.resolve_original_from_mapped(@class_a).should == @class_a
        end

      end

    end

    describe "when resolving the mapped from original" do

      context "when a mapping exists" do

        it "should return the original" do
          @class_name_map.save_mapping(@class_a, @class_b)
          @class_name_map.resolve_mapped_from_original(@class_a).should == @class_b
        end

      end

      context "when no mapping exists" do

        it "should return the class" do
          @class_name_map.resolve_mapped_from_original(@class_e).should == @class_e
        end

      end

    end

  end
end

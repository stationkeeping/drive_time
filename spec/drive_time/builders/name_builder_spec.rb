require 'spec_helper'

module DriveTime

  describe NameBuilder do

    before(:each) do
      @name_builder = NameBuilder.new
    end

    it "should combine names into a single name, adding a '.' for a middle initial" do
      # All present
      name_fields = ['First Name', 'Middle Names', 'Last Name']
      row_map = {'First Name' => 'George', 'Middle Names' => 'W', 'Last Name' => 'Bush'}
      @name_builder.build(name_fields, row_map).should == 'george_w._bush'
    end

    it "should combine names into a single name, adding no '.' for any longer middle name" do
      # All present
      name_fields = ['First Name', 'Middle Names', 'Last Name']
      row_map = {'First Name' => 'George', 'Middle Names' => 'Wo', 'Last Name' => 'Bush'}
      @name_builder.build(name_fields, row_map).should == 'george_wo_bush'
    end

  end
end

require 'spec_helper'

module DriveTime

  describe JoinBuilder do

    before(:each) do
      @join_builder = JoinBuilder.new
    end

    it "should combine values into a single value" do
      # All present
      name_fields = ['Key1', 'Key2', 'Key3']
      row_map = {'Key1' => 'Value1', 'Key2' => 'Value2', 'Key3' => 'Value3'}
      @join_builder.build(name_fields, row_map).should == 'value1_value2_value3'

    end

    it "should ignore empty fields so long as they exist" do
      name_fields = ['Key1', 'Key2', 'Key3']
      row_map = {'Key1' => 'Value1', 'Key2' => '', 'Key3' => 'Value3'}
      @join_builder.build(name_fields, row_map).should == 'value1_value3'
    end

    it "should not add anything to a single name" do
      name_fields = ['Key3']
      row_map = {'Key1' => 'Value1', 'Key2' => 'Value2', 'Key3' => 'Value3'}
      @join_builder.build(name_fields, row_map).should == 'value3'
    end

    it "should raise a MissingFieldError if a field is missing" do

      name_fields = ['Key1']
      row_map = {}

      expect { @join_builder.build(name_fields, row_map) }.to raise_error NameBuilder::MissingFieldError
    end

    it "should raise a NoFieldsError if all fields are missing" do

      name_fields = ['Key1', 'Key2', 'Key3']
      row_map = {'Key1' => '', 'Key2' => '', 'Key3' => ''}

      expect { @join_builder.build(name_fields, row_map) }.to raise_error NameBuilder::NoFieldsError
    end

  end
end

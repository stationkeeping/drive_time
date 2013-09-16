require "spec_helper"

module DriveTime

  describe JoinBuilder do

    before(:each) do
      @join_builder = JoinBuilder.new
      @class_map = double("ClassMap")
    end

    it "should combine values into a single value" do
      # All present
      field_keys = ["Key1", "Key2", "Key3"]
      model_definition = double("ModelDefinition")
      model_definition.should_receive(:value_for).with("Key1").and_return('Value1')
      model_definition.should_receive(:value_for).with("Key2").and_return('Value2')
      model_definition.should_receive(:value_for).with("Key3").and_return('Value3')
      model_definition.should_receive(:has_value_for?).with("Key1").and_return(true)
      model_definition.should_receive(:has_value_for?).with("Key2").and_return(true)
      model_definition.should_receive(:has_value_for?).with("Key3").and_return('Value3')
      @join_builder.build(field_keys, model_definition).should == "value1_value2_value3"
    end

    # it "should ignore empty fields so long as they exist" do
    #   field_keys = ['Key1', 'Key2', 'Key3']
    #   row_map = {'Key1' => 'Value1', 'Key2' => '', 'Key3' => 'Value3'}
    #   @join_builder.build(name_fields, row_map).should == 'value1_value3'
    # end

    # it "should not add anything to a single name" do
    #   name_fields = ['Key3']
    #   row_map = {'Key1' => 'Value1', 'Key2' => 'Value2', 'Key3' => 'Value3'}
    #   @join_builder.build(name_fields, row_map).should == 'value3'
    # end

    # it "should raise a MissingFieldError if a field is missing" do

    #   name_fields = ['Key1']
    #   row_map = {}

    #   expect { @join_builder.build(name_fields, row_map) }.to raise_error NameBuilder::MissingFieldError
    # end

    # it "should raise a NoFieldsError if all fields are missing" do

    #   name_fields = ['Key1', 'Key2', 'Key3']
    #   row_map = {'Key1' => '', 'Key2' => '', 'Key3' => ''}

    #   expect { @join_builder.build(name_fields, row_map) }.to raise_error NameBuilder::NoFieldsError
    # end

  end
end

require 'spec_helper'

module DriveTime

  describe Mapper do

    before(:each) do
      @mapper = Mapper.new(nil, nil, nil, nil)
    end

    # context 'build_id_for_model' do

    #   it 'should build correct id for model using basic key' do

    #     class Mapper
    #       public :build_id_for_model
    #     end

    #     mapping = {:key => 'name'}
    #     @source_converter.row_map = {'name' => 'John'}
    #     @source_converter.build_id_for_model(mapping).should == 'john'
    #   end

    #   it 'should build correct id for model using join builder' do

    #     class Mapper
    #       public :build_id_for_model
    #     end

    #     mapping = {:key => {:builder => 'join', :from_fields => ['one', 'two', 'three'] } }
    #     @source_converter.row_map = {'one' => 'Apple', 'two' => 'Orange', 'three' => 'Plum'}

    #     @source_converter.build_id_for_model(mapping).should == 'apple_orange_plum'
    #   end

    #   it 'should build correct id for model using name builder' do

    #     class Mapper
    #       public :build_id_for_model
    #     end

    #     mapping = {:key => {:builder => 'name', :from_fields => ['forename', 'middle_name', 'surname'] } }
    #     @source_converter.row_map = {'forename' => 'George', 'middle_name' => 'W', 'surname' => 'Bush'}

    #     @source_converter.build_id_for_model(mapping).should == 'george_w._bush'
    #   end

    #   it 'should raise a NoFieldNameError if no field exists with key name' do

    #     class Mapper
    #       public :build_id_for_model
    #     end

    #     mapping = {:key => 'nonsense'}
    #     @source_converter.row_map = {'name' => 'John'}

    #     expect { @source_converter.build_id_for_model(mapping) }.to raise_error Mapper::NoFieldNameError
    #   end

    # end

  end
end

require 'spec_helper'

module DriveTime

  describe WorksheetConverter do

    before(:each) do
      @worksheet_converter = WorksheetConverter.new(nil, nil, nil, nil)
    end

    context 'build_id_for_model' do

      it 'should build correct id for model using basic key' do

        class WorksheetConverter
          public :build_id_for_model
        end

        mapping = {:key => 'name'}
        @worksheet_converter.row_map = {'name' => 'John'}

        @worksheet_converter.build_id_for_model(mapping).should == 'john'
      end

      it 'should build correct id for model using join builder' do

        class WorksheetConverter
          public :build_id_for_model
        end

        mapping = {:key => {:builder => 'join', :from_fields => ['one', 'two', 'three'] } }
        @worksheet_converter.row_map = {'one' => 'Apple', 'two' => 'Orange', 'three' => 'Plum'}

        @worksheet_converter.build_id_for_model(mapping).should == 'apple_orange_plum'
      end

      it 'should build correct id for model using name builder' do

        class WorksheetConverter
          public :build_id_for_model
        end

        mapping = {:key => {:builder => 'name', :from_fields => ['forename', 'middle_name', 'surname'] } }
        @worksheet_converter.row_map = {'forename' => 'George', 'middle_name' => 'W', 'surname' => 'Bush'}

        @worksheet_converter.build_id_for_model(mapping).should == 'george_w._bush'
      end

      it 'should raise a NoFieldNameError if no field exists with key name' do

        class WorksheetConverter
          public :build_id_for_model
        end

        mapping = {:key => 'nonsense'}
        @worksheet_converter.row_map = {'name' => 'John'}

        expect { @worksheet_converter.build_id_for_model(mapping) }.to raise_error WorksheetConverter::NoFieldNameError
      end

    end

  end
end

require "spec_helper"
require "google_drive"

module DriveTime

  describe FieldExpander do

    before :each do
      @loader = Loader.new
      @loader.stub :begin_session
      @field_expander = FieldExpander.new(@loader)
      @valid_file_path = "valid_file_path"

      @invalid_token = "invalid_token"
      @valid_expand_file_token = "expand_file"
      @valid_expand_file_token_with_filename = "expand_file[#{@valid_file_path}]"
      @valid_expand_spreadsheet_token = "expand_spreadsheet"
      @valid_expand_spreadsheet_token_with_filename = "expand_spreadsheet[#{@valid_file_path}]"
      @file = double("file") # need something in the object or Ruby treats it as blank
      @file.stub :initialize
      @file_contents = "12345"
      @model_key = "model_key"
      @worksheet = double("worksheet")
      @spreadsheet = double('spreadsheet')
    end

    context "when supplied with a field containig an invalid token" do

      it "should raise a TokenExpansionError" do
        expect { @field_expander.expand(@invalid_token, @model_key) }.to raise_error TokenExpansionError
      end

    end

    context "when supplied with a field containig an 'expand_file' token" do

      context "when the file exists" do

        it "should load the file" do
          @loader.should_receive(:load_file_direct).with("#{@model_key}.txt").and_return(@file)
          @file.should_receive(:download_to_string).and_return(@file_contents)
          @field_expander.expand(@valid_expand_file_token, @model_key).should == @file_contents
        end

      end

      context "when the file doesn't exist" do

        it "should raise a TokenExpansionError" do
          @loader.stub(:load_file_direct).and_return(nil)
          expect { @field_expander.expand(@valid_expand_file_token, @model_key) }.to raise_error TokenExpansionError
        end

      end
    end

    context "when supplied with a field containig an 'expand_file' token and a filename" do

      context "when the file exists" do

        it "should load the file " do
          @loader.should_receive(:load_file_direct).with("#{@valid_file_path}.txt").and_return(@file)
          @file.should_receive(:download_to_string).and_return(@file_contents)
          @field_expander.expand(@valid_expand_file_token_with_filename, @model_key).should == @file_contents
        end

      end

      context "when the file doesn't exist" do

        it "should raise a TokenExpansionError" do
          @loader.stub(:load_file_direct).and_return(nil)
          expect { @field_expander.expand(@valid_expand_file_token_with_filename, @model_key) }.to raise_error TokenExpansionError
        end

      end

    end

    context "when supplied with a field containig an 'expand_spreadsheet' token" do

      context "when the spreadsheet exists" do

        it "should load the spreadsheet" do
          @file.stub(:worksheets).and_return([@worksheet])
          @loader.should_receive(:load_spreadsheet_direct).with(@model_key).and_return(@file)
          @field_expander.should_receive(:expand_worksheet).with(@worksheet)
          @field_expander.expand(@valid_expand_spreadsheet_token, @model_key)
        end

      end

      context "when the spreadsheet doesn't exist" do

        it "should raise a TokenExpansionError" do
          @loader.stub(:load_spreadsheet_direct).and_return(nil)
          expect { @field_expander.expand(@valid_expand_spreadsheet_token, @model_key) }.to raise_error TokenExpansionError
        end

      end

    end

    context "when supplied with a field containig an 'expand_spreadsheet' token and a spreadsheet name" do

      context "when the spreadsheet exists" do

        it "should load the spreadsheet " do
          @file.stub(:worksheets).and_return([@worksheet])
          @loader.should_receive(:load_spreadsheet_direct).with(@valid_file_path).and_return(@file)
          @field_expander.should_receive(:expand_worksheet).with(@worksheet).and_return(@file_contents)
          @field_expander.expand(@valid_expand_spreadsheet_token_with_filename, @model_key)
        end

      end

      context "when the spreadsheet doesn't exist" do

        it "should raise a TokenExpansionError" do
          @loader.stub(:load_spreadsheet_direct).and_return(nil)
          expect { @field_expander.expand(@valid_expand_spreadsheet_token_with_filename, @model_key) }.to raise_error TokenExpansionError
        end

      end

    end

  end

end

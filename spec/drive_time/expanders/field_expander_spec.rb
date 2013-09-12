require "spec_helper"
require "google_drive"

module DriveTime

  describe FieldExpander do

    before :all do
      @valid_filename_1 = "valid_filename_1"
      @valid_filename_1 = "valid_filename_2"
      @valid_token_filename = "valid token filename"
      @valid_key_1 = "key_1"
      @valid_key_2 = "key_2"
      @valid_response_1 = "valid response 1"
      @valid_response_2 = "valid response 2"
      @field_expander = FieldExpander.new()
    end

    context "without a registered expander"  do

      it "it should raise a TokenExpansionError" do
        expect{ @field_expander.expand("expand_invalid", @valid_filename_1) }.to raise_error(TokenExpansionError)
      end

    end

    context "with a registered expander"  do

      it "it should raise a TokenExpansionError for an unregistered key" do
        expander = double("Expander")
        expander.stub(:key).and_return(@valid_key_1)
        @field_expander.register_expander(expander)
        expect{ @field_expander.expand("expand_invalid", @valid_filename_1) }.to raise_error(TokenExpansionError)
      end

      it "it should expand the token for a valid key" do
        expander = double("Expander")
        expander.stub(:key).and_return(@valid_key_1)
        @field_expander.register_expander(expander)
        expander.should receive(:expand).with(@valid_filename_1).and_return(@valid_response_1)
        @field_expander.expand("expand_#{@valid_key_1}", @valid_filename_1).should == @valid_response_1
      end

      context "with a filename included in the token inside [] brackets" do

        it "it should use the filename" do
          expander = double("Expander")
          expander.stub(:key).and_return(@valid_key_1)
          @field_expander.register_expander(expander)
          expander.should receive(:expand).with(@valid_token_filename).and_return(@valid_response_1)
          @field_expander.expand("expand_#{@valid_key_1}[#{@valid_token_filename}]", @valid_filename_1).should == @valid_response_1
        end

      end

    end

    context "with multiple registered expanders"  do

      it "it should expand the token for a valid key" do
        expander_1 = double("Expander")
        expander_1.stub(:key).and_return(@valid_key_1)
        expander_2 = double("Expander")
        expander_2.stub(:key).and_return(@valid_key_2)
        @field_expander.register_expander(expander_1)
        @field_expander.register_expander(expander_2)
        expander_1.should receive(:expand).with(@valid_filename_1).and_return(@valid_response_1)
        expander_2.should receive(:expand).with(@valid_filename_2).and_return(@valid_response_2)
        @field_expander.expand("expand_#{@valid_key_1}", @valid_filename_1).should == @valid_response_1
        @field_expander.expand("expand_#{@valid_key_2}", @valid_filename_2).should == @valid_response_2
      end

    end

  end
end

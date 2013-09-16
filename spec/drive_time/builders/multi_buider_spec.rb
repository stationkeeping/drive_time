require "spec_helper"

module DriveTime

  describe MultiBuilder do

    before :each do
      @builder = MultiBuilder.new
      @valid_string = "one,two,three"
      @valid_string_with_newlines = "\none,\ntwo,\nthree\n"
    end

    context "for a valid string" do

      it "should split a string on commas" do
        @builder.build(@valid_string).should == ["one", "two", "three"]
      end

      it "should remove all newlines" do
        @builder.build(@valid_string_with_newlines).should == ["one", "two", "three"]
      end

    end

    it "should return an empty array for an empty string" do
      @builder.build("").should == []
    end

  end

end

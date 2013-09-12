require "spec_helper"

# Mapped from Group

module DriveTime

  # Fixtures
  module One
    class Two
    end
  end

  describe DriveTime do

    describe "underscore_from_text" do

      it "should convert a text string to a downcased, underscored string with leading and trailing whitespace removed" do
        input_string = " a Test STRING-with-spaces- AND words "
        expected_string = "a_test_string-with-spaces-_and_words"
        DriveTime.underscore_from_text(input_string).should == expected_string
      end
    end

    describe "class_name_from_title" do

      it "should convert a lower-case text string to a class name" do
        input_string = "class name"
        expected_string = "ClassName"
        DriveTime.class_name_from_title(input_string).should == expected_string
      end

      it "should convert a sentence-case text string to a class name" do
        input_string = "Class name"
        expected_string = "ClassName"
        DriveTime.class_name_from_title(input_string).should == expected_string
      end

      it "should convert a title-case text string to a class name" do
        input_string = "Class Name"
        expected_string = "ClassName"
        DriveTime.class_name_from_title(input_string).should == expected_string
      end

    end

    describe "is_affirmative" do

      it "should only treat yes and y (no matter the case) as affirmative" do
        # Positive
        DriveTime.is_affirmative?("yes").should be_true
        DriveTime.is_affirmative?("YES").should be_true
        DriveTime.is_affirmative?("Yes").should be_true
        DriveTime.is_affirmative?("y").should be_true
        DriveTime.is_affirmative?("Y").should be_true
        DriveTime.is_affirmative?(" Yes ").should be_true
        # Negative
        DriveTime.is_affirmative?("No").should be_false
        DriveTime.is_affirmative?("").should be_false
        DriveTime.is_affirmative?("N").should be_false
        DriveTime.is_affirmative?("Yeses").should be_false
        DriveTime.is_affirmative?("Example").should be_false
      end
    end

    describe "check_string_for_boolean" do

      it "should convert a string with a value of y, yes or true (in any case) to a boolean of true" do
        DriveTime.check_string_for_boolean("Y").should be_true
        DriveTime.check_string_for_boolean("y").should be_true
        DriveTime.check_string_for_boolean("YES").should be_true
        DriveTime.check_string_for_boolean("Yes").should be_true
        DriveTime.check_string_for_boolean("yes").should be_true
        DriveTime.check_string_for_boolean("TRUE").should be_true
        DriveTime.check_string_for_boolean("True").should be_true
        DriveTime.check_string_for_boolean("true").should be_true
      end

      it "should convert a string with a value of n, no or false (in any case) to a boolean of true" do
        DriveTime.check_string_for_boolean("N").should be_false
        DriveTime.check_string_for_boolean("n").should be_false
        DriveTime.check_string_for_boolean("NO").should be_false
        DriveTime.check_string_for_boolean("No").should be_false
        DriveTime.check_string_for_boolean("no").should be_false
        DriveTime.check_string_for_boolean("FALSE").should be_false
        DriveTime.check_string_for_boolean("False").should be_false
        DriveTime.check_string_for_boolean("false").should be_false
      end

      it "should allow return all other values untouched" do
        DriveTime.check_string_for_boolean("A").should == "A"
        DriveTime.check_string_for_boolean("Abc Def").should == "Abc Def"
        DriveTime.check_string_for_boolean("Ohyes").should == "Ohyes"
        DriveTime.check_string_for_boolean("Nope").should == "Nope"
      end

    end

    describe "namespaced_class_name" do

      it "should convert a classname and namespace into a class constant" do
        DriveTime.namespaced_class_name("Two", "DriveTime::One").should == DriveTime::One::Two
      end

      it "should raise an exception if the class doesn't exist" do
        expect { DriveTime.namespaced_class_name("Invalid", "DriveTime::One") }.to raise_error(NameError)
      end

      it "should convert a classname with a blank namespace into a class constant" do
        DriveTime.namespaced_class_name("String", "").should == String
      end

      it "should convert a classname with no namespace into a class constant" do
        DriveTime.namespaced_class_name("String").should == String
      end

    end

  end
end

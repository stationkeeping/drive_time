require 'spec_helper'

describe DriveTime do

  it 'should process string correctly' do
    input_string = ' a Test STRING-with-spaces- AND hyphens '
    # All lower case
    # Underscores replace speces and hyphens
    # Leading and trailing whitespace is removed
    expected_string = 'a_test_string_with_spaces__and_hyphens'
    result_string = DriveTime.underscore_from_text input_string
    result_string.should == expected_string
  end

  it 'should process a title to a class' do
    input_string = "Example Title Class"
    expected_string = "ExampleTitleClass"
    result_string = DriveTime.class_name_from_title input_string
    result_string.should == expected_string
  end

  it 'should only treat yes and y (in any case) as affirmative' do
    # Positive
    DriveTime.is_affirmative?('yes').should be_true
    DriveTime.is_affirmative?('YES').should be_true
    DriveTime.is_affirmative?('Yes').should be_true
    DriveTime.is_affirmative?('y').should be_true
    DriveTime.is_affirmative?('Y').should be_true
    DriveTime.is_affirmative?(' Yes ').should be_true
    # Negative
    DriveTime.is_affirmative?('No').should be_false
    DriveTime.is_affirmative?('').should be_false
    DriveTime.is_affirmative?('N').should be_false
    DriveTime.is_affirmative?('Yeses').should be_false
    DriveTime.is_affirmative?('Example').should be_false
  end

end
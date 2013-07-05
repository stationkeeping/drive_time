# require 'spec_helper'

# module DriveTime

#   describe NameBuilder do

#     before(:each) do
#       @name_builder = NameBuilder.new
#     end

#     it "should combine names into a single name correctly" do

#       # All present
#       name_fields = ['First Name', 'Middle Names', 'Last Name']
#       row_map = {'First Name' => 'George', 'Middle Names' => 'W', 'Last Name' => 'Bush'}
#       @name_builder.build(name_fields, row_map).should == 'george_w._bush'

#       # No value for field (but key exists)
#       row_map = {'First Name' => 'George', 'Middle Names' => '', 'Last Name' => 'Bush'}
#       @name_builder.build(name_fields, row_map).should == 'george_bush'

#       name_fields = ['Last Name']
#       row_map = {'First Name' => 'George', 'Middle Names' => 'W', 'Last Name' => 'Bush'}
#       @name_builder.build(name_fields, row_map).should == 'bush'

#     end

#     it "should raise a MissingFieldError if a field is missing" do

#       name_fields = ['First Name']
#       row_map = {}

#       expect { @name_builder.build(name_fields, row_map) }.to raise_error NameBuilder::MissingFieldError
#     end

#     it "should raise a NoFieldsError if a field is missing" do

#       name_fields = ['First Name', 'Middle Names', 'Last Name']
#       row_map = {'First Name' => '', 'Middle Names' => '', 'Last Name' => ''}

#       expect { @name_builder.build(name_fields, row_map) }.to raise_error NameBuilder::NoFieldsError
#     end

#   end
# end

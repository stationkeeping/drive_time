require 'spec_helper'

module DriveTime

	describe 'BiDirectionalHash' do

		before(:each) do
			@hash = BiDirectionalHash.new
		end
		
		it 'should correctly declare if a value exists for a key' do
			@hash.insert('A', 1);
			@hash.insert('B', 2);
			@hash.insert(3, 'A');

			@hash.has_value_for_key('A').should be_true
			@hash.has_value_for_key('B').should be_true
			@hash.has_value_for_key(3).should be_true
			@hash.has_value_for_key('Nope').should be_false
		end

		it 'should correctly declare if a key exists for a value' do
			@hash.insert('A', 1);
			@hash.insert('B', 2);
			@hash.insert(3, 'A');

			@hash.has_key_for_value(1).should be_true
			@hash.has_key_for_value(2).should be_true
			@hash.has_key_for_value('A').should be_true
			@hash.has_key_for_value('Nope').should be_false
		end

		it 'should allow values to be looked up using keys' do
			@hash.insert('A', 1);
			@hash.insert('B', 2);
			@hash.insert(3, 'A');

			@hash.value_for_key('A').should == 1
			@hash.value_for_key('B').should == 2
			@hash.value_for_key(3).should == 'A'
		end

		it 'should allow keys to be looked up using values' do
			@hash.insert('A', 1);
			@hash.insert('B', 2);
			@hash.insert(3, 'A');

			@hash.key_for_value(1).should == 'A'
			@hash.key_for_value(2).should == 'B'
			@hash.key_for_value('A').should == 3
		end

	end
end
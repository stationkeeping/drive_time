require 'spec_helper'

class ModelBase

  def initialize(data, params)
  end

  def save!
  end
end

module DriveTime

  class Act < ModelBase
    attr_accessor :members
    def initialize(data, params)
      self.members = Array.new
    end
  end

  class Album < ModelBase
    attr_accessor :label
    attr_accessor :act
    attr_accessor :tracks
    def initialize(data, params)
      self.tracks = Array.new
    end
  end

  class Label < ModelBase; end

  class Member < ModelBase; end

  class Track < ModelBase; end

  describe DriveTime do

    context 'with full spreadsheet and mapping' do
      it 'should load spreadsheet and map to models' do
        mappings_path = File.join(File.dirname(__FILE__),'../../fixtures/mapping.yml')
        converter = SpreadsheetsConverter.new
        converter.load mappings_path
      end

    end

  end
end
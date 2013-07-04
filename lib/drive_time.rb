require "drive_time/version"

require "log4r"
require 'google_drive'
require 'deep_end'
require 'log4r'
require 'active_support'

require 'drive_time/model_store'
require 'drive_time/spreadsheet_loader'
require 'drive_time/builders/name_builder'
require 'drive_time/converters/spreadsheets_converter'
require 'drive_time/converters/spreadsheet_converter'
require 'drive_time/converters/worksheet_converter'

module DriveTime
  
  include ActiveSupport::Inflector
  include Log4r

  # Set up logging
  formatter = PatternFormatter.new(:pattern => "[%c] %M")
  outputter = Outputter.stdout
  outputter.formatter = formatter
  
  # Create constants for loggers - available in inner classes
  Logger = Log4r::Logger.new 'main'
  Logger.outputters = outputter

  # Store the mapping on the spreadsheets and worksheets
  class GoogleDrive::Spreadsheet
    attr_accessor :mapping
  end

  class GoogleDrive::Worksheet
    attr_accessor :mapping
  end

  def self.underscore_from_text(text)
    text.
      strip.
      downcase.
      tr(" ", "_").
      tr("-", "_")
  end

  def self.class_name_from_title(title)
    self.underscore_from_text(title).classify
  end

  def self.is_affirmative?(value)
    value.
      strip.
      downcase == 'yes' || value.downcase == 'y'
  end

end

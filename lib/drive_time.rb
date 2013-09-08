require "drive_time/version"

require "log4r"
require 'google_drive'
require 'deep_end'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/module'

require 'drive_time/mapping'
require 'drive_time/model_store'
require 'drive_time/field_expander'
require 'drive_time/bi_directional_hash'
require 'drive_time/spreadsheet_loader'
require 'drive_time/class_name_map'
require 'drive_time/builders/join_builder'
require 'drive_time/builders/name_builder'
require 'drive_time/converters/spreadsheets_converter'
require 'drive_time/converters/worksheet_converter'

module Log4r
  class Logger
    def log_as_header(message)
      puts "\n"
      info "=============================================================================="
      info "#{message}"
      info '=============================================================================='
    end

    def log_as_sub_header(message)
      puts "\n" if self.level <= DEBUG
      debug "--------------------------------------------------------------------------------"
      debug "  #{message}"
      debug '--------------------------------------------------------------------------------'
    end
  end
end

module DriveTime

  mattr_accessor :log_level

  class MissingAssociationError < StandardError; end

  include ActiveSupport::Inflector
  include Log4r

  # Set up logging
  formatter = PatternFormatter.new(:pattern => "[%c] %M")
  outputter = Outputter.stdout
  outputter.formatter = formatter

  @@log_level = INFO
  # Create constants for loggers - available in inner classes
  Logger = Log4r::Logger.new ' Primary     '
  Logger.level = @@log_level
  Logger.outputters = outputter

  # Store the mapping on the spreadsheets and worksheets
  class GoogleDrive::Spreadsheet
    attr_accessor :mapping
  end

  class GoogleDrive::Worksheet
    attr_accessor :mapping
  end

  def self.underscore_from_text(text)
    text.strip.downcase.parameterize('_')
  end

  def self.class_name_from_title(title)
    self.underscore_from_text(title).classify
  end

  def self.is_affirmative?(value)
    return false if !value
    value.
      strip.
      downcase == 'yes' || value.downcase == 'y'
  end

  def self.log_level=(log_level)
    @@log_level = log_level
    Logger.level = log_level
  end

end

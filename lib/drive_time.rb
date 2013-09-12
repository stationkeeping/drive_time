require "drive_time/version"

require "log4r"
require 'google_drive'
require 'deep_end'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/module'

require 'drive_time/model_store'
require 'drive_time/expanders/field_expander'
require 'drive_time/expanders/google_file_expander'
require 'drive_time/expanders/google_spreadsheet_expander'
require 'drive_time/bi_directional_hash'
require 'drive_time/loaders/google_drive_loader'
require 'drive_time/class_name_map'
require 'drive_time/builders/join_builder'
require 'drive_time/builders/name_builder'
require 'drive_time/builders/multi_builder'
require 'drive_time/converters/spreadsheets_converter'
require 'drive_time/converters/source_converter'
require 'drive_time/source_adapters/worksheet_source_adapter'
require 'drive_time/logging'

module DriveTime

  mattr_accessor :log_level

  class MissingAssociationError < StandardError; end
  class MissingSpreadsheetError < StandardError; end
  class MissingWorksheetError < StandardError; end

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

  def self.check_string_for_boolean(value)
    downcased = value.downcase
    if %w[y yes true].include? downcased
      true
    elsif %w[n no false].include? downcased
      false
    else
      value
    end
  end

  def self.namespaced_class_name(class_name, namespace = nil)
    class_name = "#{namespace}::#{class_name}" unless namespace.blank?
    class_name.constantize
  end

  def self.log_level=(log_level)
    @@log_level = log_level
    Logger.level = log_level
  end

end

require "drive_time/version"

require "log4r"
require "google_drive"
require "deep_end"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext/hash"
require "active_support/core_ext/module"

require "drive_time/model_store"
require "drive_time/logging"
require "drive_time/class_map"
require "drive_time/mapper"
require "drive_time/initialisers/base_initialiser"
require "drive_time/model_definition"
require "drive_time/field_expander"

require "drive_time/builders/join_builder"
require "drive_time/builders/name_builder"
require "drive_time/builders/multi_builder"


module DriveTime

  mattr_accessor :log_level

  class MissingAssociationError < StandardError; end
  class MissingSpreadsheetError < StandardError; end
  class MissingWorksheetError < StandardError; end
  class NoClassError < StandardError; end
  class MissingFieldError < StandardError; end
  class ValidationError < StandardError; end

  include ActiveSupport::Inflector
  include Log4r

  # Set up logging
  formatter = PatternFormatter.new(:pattern => "[%c] %M")
  outputter = Outputter.stdout
  outputter.formatter = formatter

  @@log_level = INFO
  # Create constants for loggers - available in inner classes
  Logger = Log4r::Logger.new " Primary     "
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
    text.strip.downcase.underscore.parameterize("_")
  end

  def self.class_name_from_title(title)
    self.underscore_from_text(title).classify
  end

  def self.is_affirmative?(value)
    return false if !value
    %w[y yes true].include? value.strip.downcase
  end

  def self.is_negative?(value)
    return false if !value
    %w[n no false].include? value.strip.downcase
  end

  def self.check_string_for_boolean(value)
    if is_affirmative?(value)
      true
    elsif is_negative?(value)
      false
    else
      value
    end
  end

  def self.namespaced_class(class_name, namespace = nil)
    class_name = "#{namespace}::#{class_name}" unless namespace.blank?
    class_name.constantize
  end

  def self.log_level=(log_level)
    @@log_level = log_level
    Logger.level = log_level
  end

end

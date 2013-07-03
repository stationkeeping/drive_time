require "drive_time/version"
require "log4r"
require "google_drive"
require "deep_end"

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

  ModelStoreLogger = Log4r::Logger.new 'store'
  ModelStoreLogger.outputters = outputter

  # Store the mapping on the spreadsheets and worksheets
  class GoogleDrive::Spreadsheet
    attr_accessor :mapping
  end
  class GoogleDrive::Worksheet
    attr_accessor :mapping
  end

  def self.underscore_from_text(value)
    value.
      strip.
      downcase.
      tr(" ", "_").
      tr("-", "_")
  end

  def self.classify_from_title(value)
    self.underscore_from_text(value).classify
  end

  def self.is_affirmative?(value)
    value.downcase == 'yes' || value.downcase == 'y'
  end

  # Store model instances by class and link
  # This way we can look them up as needed to
  # satisfy dependencies and avoid duplication
  class ModelStore

    require 'ostruct'

    @@store = {}

    # Store the model by class to avoid key collisions
    def self.add_model(instance, key)
      # Sanitise key
      key = DriveTime.underscore_from_text(key)
      clazz = instance.class.to_s
      ModelStoreLogger.info "Adding model with key #{key} of class #{instance.class.to_s}"
      @@store[clazz] = {} if @@store[clazz].blank?
      @@store[clazz][key] = instance
    end

    def self.get_model(clazz, key)
      ModelStoreLogger.info "Requested model with key #{key} of class #{clazz}"

      if(key == 'poornima_chikarmane')
        ModelStoreLogger.info @@store[clazz.to_s].inspect
      else

      end

      model = @@store[clazz.to_s][key]
      if model.blank?
        if @@store[clazz.to_s].blank?
          raise "No class of type: #{clazz} in the store"
        else
          raise "No #{clazz} model with a key of #{key} in the store"
        end
      end
      return model
    end

  end

  # A manifest of Spreadsheet items with dependency management
  class Manifest

    include DeepEnd

    # Items in order satisfying dependencies
    def items
      return @dependency_graph.resolved_dependencies
    end

    def initialize()
      @dependency_graph = DeepEnd::Graph.new
    end

    def addItem(item, dependencies=[])
      @dependency_graph.add_dependency item, dependencies
    end

  end

  class Loader

    attr_reader :spreadsheet

    def initialize
      @session = GoogleDrive.login( ENV['GOOGLE_USERNAME'], ENV['GOOGLE_PASSWORD'])
    end

    def load(title)
      spreadsheet = @session.spreadsheet_by_title(title)
      raise "Spreadsheet #{title} not found" if spreadsheet.nil?
      return spreadsheet
    end

  end

  class SpreadsheetsConverter
    require 'active_support/inflector'

    def initialize()
      Logger.info 'Beginning Spreadsheet Conversion'
      @manifest = Manifest.new
      @loader = DriveTime::Loader.new
    end

    def load(mappings_path)
        mappings = YAML::load File.open(mappings_path)
        convert mappings
    end

    def convert(mappings)
        spreadsheets = []
        # First download the spreadsheets
        mappings['spreadsheets'].each do |spreadsheet_mapping|
          spreadsheet =  @loader.load(spreadsheet_mapping['title'])
          raise "No spreadsheet with a title: #{spreadsheet_mapping['title']} available" if spreadsheet.nil?
          spreadsheet.mapping = spreadsheet_mapping
          spreadsheets << spreadsheet
        end

        # Now sort their dependencies before converting them
        spreadsheets.each do |spreadsheet|
          dependencies = []
          if spreadsheet.mapping['dependencies']
            # Run through each dependency
            spreadsheet.mapping['dependencies'].each do |dependency_title|
              # And find the spreadsheet which satisfies it
              spreadsheets.each do |spreadsheet|
                if spreadsheet.title == dependency_title
                  dependencies << spreadsheet
                end
              end
              raise "Missing spreadsheet dependency #{spreadsheet.mapping['title']} needs #{dependency_title}" if dependencies.count < spreadsheet.mapping['dependencies'].count
            end
          end
          @manifest.addItem spreadsheet, dependencies
        end

        # Now that dependencies are checked and ordered, convert load Worksheets
        @manifest.items.each{|spreadsheet| WorksheetsConverter.new spreadsheet }
      end
  end

  class WorksheetsConverter

    def initialize(spreadsheet)
      @manifest = Manifest.new
      convert spreadsheet
    end

    def convert(spreadsheet)

      worksheets = []
      # First get the worksheets
      if spreadsheet.mapping['worksheets']
        spreadsheet.mapping['worksheets'].each do |worksheet_mapping|
          worksheet = spreadsheet.worksheet_by_title worksheet_mapping['title']
          raise "No worksheet with a title: #{worksheet_mapping['title']} available" if worksheet.nil?
          worksheet.mapping = worksheet_mapping
          worksheets << worksheet
        end
      end

      # Now sort their dependencies before converting them
      worksheets.each do |worksheet|
        associations = []
        # Run through each association
        if worksheet.mapping['associations']
          worksheet.mapping['associations'].each do |value|
            # And find the worksheet that satisfies it
            worksheets.each do |worksheet|
              if DriveTime.underscore_from_text(worksheet.title) == value['name']
                associations << worksheet
              end
            end
          end
        end
        @manifest.addItem worksheet, associations
      end 
      # Convert the worksheets
      @manifest.items.each{|worksheet| WorksheetConverter.new worksheet }
    end
  end

  class WorksheetConverter

    def initialize(worksheet)
      convert_worksheet worksheet
    end

    def convert_worksheet(worksheet)
      # Use the spreadsheet name unless 'map_to_class' is set
      class_name = worksheet.mapping['map_to_class'] || DriveTime.classify_from_title(worksheet.title)
      Logger.info "Converting Worksheet #{worksheet.title} to class #{class_name}"
      # Check class exists - better we know immediately
      begin
        clazz = class_name.constantize
      rescue
        raise "Worksheet named #{worksheet.title} doesn't exists as class #{class_name}"
      end

      rows = worksheet.rows.dup

      # Remove the first row and use it for field-names
      fields = rows.shift.map{ |row|
        row
      }

      # Reject rows of only empty strings (empty cells).
      rows.reject! {|row| row.all?(&:empty?)}

      rows.each do |row|
        generate_model_from_row clazz, worksheet.mapping, fields, row
      end

    end

    def generate_model_from_row(clazz, mapping, fields, row)
      # Create a hash of field-names and row cell values
      row_map = {}
      Logger.info "Mapping fields to cells"
      row.dup.each_with_index do |cell, index|
        # Sanitise v
        field_name = DriveTime.underscore_from_text fields[index]
        row_map[field_name] = row[index]
        Logger.info "- #{field_name} -> #{row[index]}"
      end

      # If a row has been marked as not complete, ignore it

      if row_map['complete'] == 'No'
        Logger.info 'Row marked as not complete. Ignoring'
        return
      end

      # Build hash ready to pass into model
      model_fields = row_fields_to_model_fields mapping, row_map
      Logger.info "Creating Model with Model Fields #{model_fields.to_s}"
      # Create new model
      model = clazz.new model_fields, without_protection: true
      # Add its associations
      add_associations model, mapping, row_map
      # Store the model using its ID
      model_key = key_for_model mapping, row_map
      ModelStore.add_model model, model_key
    end

    def row_fields_to_model_fields(mapping, row_map)
      model_fields = {}
      # Run through the mapping, pulling values from row_map as required
      mapping['fields'].each do |key, value|
        if value == 'auto'
          model_fields[key] = row_map[key]
        else
          raise "Illegal field #{key} in worksheet #{mapping['title']}"
        end
      end
      return model_fields
    end

    def add_associations(model, mapping, row_map)
      Logger.info "Adding associations to model"
      # Are there any assocations defined?
      if mapping['associations']
        mapping['associations'].each do |value|
          # Use the spreadsheet name unless 'map_to_class' is set
          unless value['map_to_class'].present?
            class_name = value['name'].classify
          else
            class_name = value['map_to_class']
          end

          # Get class reference using class name
          begin
            clazz = class_name.constantize
          rescue
            raise "Association defined in worksheet #{mapping['title']} doesn't exist as class #{class_name}"
          end

          # Assemble model instances that have already been created to satisfy associations 
          models = []
          # If a converter is defined, transform the cell contents
          if value['converter']
            if value['converter'] == 'multi' # It's a multi value, so split by comma
              cell_value = row_map[class_name.underscore.pluralize]
              raise "No field #{class_name} to satisfy association" if cell_value.blank? && value['optional'] != true;
              components = cell_value.split ','
              components.each do |component|
                models << get_model_for_id(DriveTime.underscore_from_text(component), class_name)
              end
            elsif value['converter'] == 'use_fields' # Use column names as values if cell contains 'yes' or 'y'
              value['field_names'].each do |field_name|
                field_value = row_map[field_name]

                if DriveTime.is_affirmative? field_value
                  models << get_model_for_id(field_name, class_name)
                end
              end
            end

          else # It's a single text value, so convert it to an ID
            cell_value = row_map[class_name.underscore]
            raise "No field #{class_name.underscore} to satisfy association" if cell_value.blank?
            models << get_model_for_id(cell_value, clazz)
          end

          # We now have one or more models with which to associate our model
          models.each do |associated_model|

            Logger.info "Model #{associated_model}"
            unless value['inverse'] == true
              association_name = class_name.underscore
              puts 'NOT INVERSE'+association_name
              if value['singular'] == true
                Logger.info "- Adding association #{associated_model} to #{model}::#{association_name}"
                model.send association_name, associated_model
              else
                association_name = association_name.pluralize
                associations = model.send association_name
                Logger.info "- Adding association #{associated_model} to #{model}::#{association_name}"
                associations << associated_model
              end
            else # The relationship is actually inverted, so save the model as an association on the associated_model
              model_name = model.class.name.underscore
              puts 'INVERSE'+model_name
              if value['singular'] == true
                Logger.info "- Adding association #{model} to #{associated_model}::#{association_name}"
                associated_model.send model_name, model
              else
                model_name = model_name.pluralize
                puts '- assoc name'+model_name.pluralize
                associations = associated_model.send model_name
                Logger.info "- Adding association #{model} to #{associated_model}::#{model_name}"
                associations << model
              end
            end
            model.save!
          end
        end
      end
    end

    def get_model_for_id(title, clazz)
      model_key = DriveTime.underscore_from_text title
      return ModelStore.get_model clazz, model_key
    end

    def key_for_model(mapping, row_map)
      key_node = mapping['key']
      if key_node.is_a? Hash
        if key_node['converter'] == 'name'
          key = NameConverter.convert key_node['from_fields'], row_map
        else
          raise "No converter for key on worksheet #{mapping['title']}"
        end

      else # If it's a string, it refers to a spreadsheet column
        key_attribute = key_node

        # Is there a column
        begin
          key = row_map[key_attribute]
        rescue
          raise "No column #{key_attribute} on worksheet #{mapping['title']}"
        end
      end
    end
  end

  # Take a series of names and assemble them into a single name for use as an id
  class NameConverter

    # Fields to use for names
    def self.convert(name_fields, row_map)
      names = []

      name_fields.each do |name_key|
        names << DriveTime.underscore_from_text(row_map[name_key]) if row_map[name_key].present?
      end

      names.each_with_index do |name, index|
        # Add a period to initials
        if name.length == 1
          names[index] = "#{name}."
        end
      end
      names.join('_').downcase
    end
  end

end

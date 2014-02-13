require "drive_time/loaders/google_drive_loader"
require "drive_time/providers/google_file_provider"
require "drive_time/mapping/google_drive_mapping"
require "drive_time/providers/google_spreadsheet_provider"
require "drive_time/mapping/spreadsheet_mapping"
require "drive_time/mapping/worksheet_mapping"
require "drive_time/mapping/association_mapping"
require "drive_time/mapping/validators/worksheet_mapping_validator"
require "drive_time/source/worksheet_source"

module DriveTime

  # The Google Drive Converter is responsible for turning Google Drive Spreadsheets into Source
  # objects to pass to the sources converter.
  class GoogleDriveInitialiser < BaseInitialiser

    def initialize()
      super
      @loader = GoogleDriveLoader.new
      @expander.register_provider(GoogleFileProvider.new(@loader))
      @expander.register_provider(GoogleSpreadsheetProvider.new(@loader))
    end

    protected

    def aquire_source(mappings)
      spreadsheets = download_spreadsheets(GoogleDriveMapping.new(mappings))
      # Download all worksheets from all spreadsheets
      worksheets = spreadsheets.flat_map do |spreadsheet|
        # Download and combine worksheets into single Array
        download_worksheets(spreadsheet)
      end

      # Order the worksheets so they are created in a dependency-satisfying order
      worksheets = order_worksheets_by_dependencies(worksheets)
      # Convert the worksheets to source
      worksheets.each do |worksheet|
        WorksheetSource.new(worksheet, @expander).model_definitions.each do |model_definition|
          Mapper.new(@model_store).convert(model_definition)
        end
      end
      save_models
    end

    def download_spreadsheets(mapping)
      # First download the spreadsheets
      spreadsheets =  mapping.spreadsheets.map do |spreadsheet_mapping|
        spreadsheet =  @loader.load_spreadsheet(spreadsheet_mapping.title)
        raise MissingSpreadsheetError "No spreadsheet with a title: #{spreadsheet_mapping['title']} available" if spreadsheet.nil?
        # Store mapping on the spreadsheet
        spreadsheet.mapping = spreadsheet_mapping
        spreadsheet
      end
    end

    def download_worksheets(spreadsheet)
      worksheets = spreadsheet.mapping.worksheets.map do |worksheet_mapping|
        worksheet = @loader.load_worksheet_from_spreadsheet(spreadsheet, worksheet_mapping.title)
        worksheet.mapping = worksheet_mapping
        worksheet
      end
    end

    def order_worksheets_by_dependencies(worksheets)
      Logger.log_as_header "Calculating worksheet dependencies"
      # Now sort their dependencies before converting them
      worksheets.each do |worksheet|
        Logger.debug "Worsheet named #{worksheet.title}"
        associations = associations_for_worksheet(worksheet, worksheets)
        associations.each { |association| Logger.debug " - #{association.title}" }
        @dependency_graph.add_dependency(worksheet, associations)
      end
      return @dependency_graph.resolved_dependencies
    end

    def associations_for_worksheet(dependent_worksheet, worksheets)
      associations = []
      # Run through each association
      dependent_worksheet.mapping.associations.each do |association_mapping|
        association_mapping.names.each{ |name| associations << worksheet_for_association(name, worksheets) }
      end
      return associations
    end

    def worksheet_for_association(name, worksheets)
      # And find the worksheet that satisfies it
      worksheets.each { |worksheet| puts "#{name} vs #{worksheet.title}"; return worksheet if name == worksheet.title }
      raise MissingAssociationError, "No worksheet #{name} to satisfy multi association"
    end

  end
end
module DriveTime

  class SpreadsheetsConverter

    def initialize()
      @dependency_graph = DeepEnd::Graph.new
      @loader = DriveTime::Loader.new
      @model_store = ModelStore.new(DriveTime::log_level)
      @class_name_map = ClassNameMap.new
    end

    # Load mappings YML file
    def load(mappings_path)
      mappings = ActiveSupport::HashWithIndifferentAccess.new(YAML::load File.open(mappings_path))
      @namespace = mappings[:namespace]
      spreadsheets = download_spreadsheets(mappings)

      worksheets = []
      spreadsheets.each do |spreadsheet|
        # Create a map containing any class mappings
        build_class_map spreadsheet
        # Download and combine worksheets into single Array
        downloaded_worksheets = download_worksheets(spreadsheet)
        worksheets.concat(downloaded_worksheets)
      end

      worksheets = order_worksheets_by_dependencies( worksheets )

      # Convert the worksheets
      worksheets.each do |worksheet|
        WorksheetConverter.new(@model_store, @class_name_map, @loader, @namespace).convert(worksheet)
      end

      # Now all the models exist, save them without problems from missing associations triggering
      # validation failiures
      @model_store.save_all
      Logger.log_as_header "Conversion Complete. Woot Woot."
    end

    protected

    def download_spreadsheets(mappings)
      # First download the spreadsheets
     spreadsheets =  mappings[:spreadsheets].map do |spreadsheet_mapping|
        spreadsheet =  @loader.load_spreadsheet(spreadsheet_mapping[:title])
        raise MissingSpreadsheetError "No spreadsheet with a title: #{spreadsheet_mapping['title']} available" if spreadsheet.nil?
        # Store mapping on the spreadsheet
        spreadsheet.mapping = spreadsheet_mapping
        spreadsheet
      end
      return spreadsheets
    end

    def download_worksheets(spreadsheet)
      worksheet_mappings = spreadsheet.mapping[:worksheets]
      worksheets = []
      if worksheet_mappings
        worksheet_mappings.each do |worksheet_mapping|
          title = worksheet_mapping[:title]
          worksheet = @loader.load_worksheet_from_spreadsheet spreadsheet, title
          raise MissingWorksheetError "No worksheet with a title: #{worksheet_mapping['title']} available" if worksheet.nil?
          worksheet.mapping = worksheet_mapping
          worksheets << worksheet
        end
      end
      return worksheets
    end

    def order_worksheets_by_dependencies(worksheets)
      Logger.log_as_header "Calculating worksheet dependencies"
      # Now sort their dependencies before converting them
      worksheets.each do |worksheet|
        Logger.debug "Worsheet named #{worksheet.title}"
        associations = find_associations worksheet, worksheets
        associations.each { |association| Logger.debug " - #{association.title}" }
        @dependency_graph.add_dependency worksheet, associations
      end
      return @dependency_graph.resolved_dependencies
    end

    def find_associations(dependent_worksheet, worksheets)

      dependent_associations_mapping = dependent_worksheet.mapping[:associations]

      associations = []
      if dependent_associations_mapping
        # Run through each association
        dependent_associations_mapping.each do |association_mapping|
          # Handle possible polymorphic association
          # If name is an array, we need to add each possibility as a dependency
          names = []
          if association_mapping[:name].is_a? Array
            names = association_mapping[:name]
          else
            names << association_mapping[:name]
          end
          names.each do |name|
            associations << worksheet_for_association(name, worksheets)
          end
        end
      end
      return associations
    end

    def worksheet_for_association(name, worksheets)
      # And find the worksheet that satisfies it
      worksheets.each do |worksheet|
        # If the name matches we have a dependent relationship
        if name == DriveTime.underscore_from_text(worksheet.title)
          return worksheet
        end
      end
      raise MissingAssociationError, "No worksheet #{name} to satisfy multi association"
    end

    def build_class_map(spreadsheet)
      worksheets_mapping = spreadsheet.mapping[:worksheets]
      if worksheets_mapping.present?
        worksheets_mapping.each do |worksheet_mapping|
          class_name = DriveTime.class_name_from_title(worksheet_mapping[:title])
          mapped_class_name = worksheet_mapping[:map_to_class]
          @class_name_map.save_mapping(class_name, mapped_class_name)
        end
      end
    end

  end
end

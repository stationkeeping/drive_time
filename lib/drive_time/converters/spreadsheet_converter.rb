module DriveTime

  class SpreadsheetConverter

    def initialize(model_store, loader)
      @dependency_graph = DeepEnd::Graph.new
      @class_name_map = ClassNameMap.new
      @model_store = model_store
      @loader = loader
    end

    def convert(spreadsheet)
      @spreadsheet = spreadsheet
      worksheets = order_worksheets_by_dependencies( load_worksheets spreadsheet.mapping[:worksheets] )
      # Convert the worksheets
      worksheets.each do |worksheet|
        WorksheetConverter.new(@model_store, @class_name_map).convert(worksheet)
      end
    end

    def load_worksheets(worksheet_mappings)
      worksheets = []
      if worksheet_mappings
        worksheet_mappings.each do |worksheet_mapping|
          title = worksheet_mapping[:title]
          worksheet = @loader.load_worksheet_from_spreadsheet @spreadsheet, title
          raise "No worksheet with a title: #{worksheet_mapping['title']} available" if worksheet.nil?
          worksheet.mapping = worksheet_mapping
          worksheets << worksheet
        end
      end
      return worksheets
    end

    def order_worksheets_by_dependencies(worksheets)
      # Now sort their dependencies before converting them
      worksheets.each do |worksheet|
        associations = find_associations worksheet, worksheets
        @dependency_graph.add_dependency worksheet, associations
      end 
      return @dependency_graph.resolved_dependencies
    end

    def find_associations(dependent_worksheet, worksheets)
      associations_mapping = dependent_worksheet.mapping[:associations]
      associations = []
      if associations_mapping
        # Run through each association
        associations_mapping.each do |association_mapping|
          # And find the worksheet that satisfies it
          worksheets.each do |worksheet|
             # If the name matches we have a dependent relationship
            if DriveTime.underscore_from_text(worksheet.title) == association_mapping[:name]
              unless association_mapping[:inverse] == true
                # If the value isn't inverse, add it to the list of associations
                associations << worksheet
              else
                # Add the inverted relationship immediately
                @dependency_graph.add_dependency worksheet, [dependent_worksheet]
              end
            end
          end
        end
      end
      return associations
    end

  end
end
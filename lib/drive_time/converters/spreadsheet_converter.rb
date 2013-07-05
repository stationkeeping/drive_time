module DriveTime

  class SpreadsheetConverter

    def initialize(model_store, loader)
      @dependency_graph = DeepEnd::Graph.new
      @model_store = model_store
      @loader = loader
    end

    def convert(spreadsheet)
      worksheets = []
      # First get the worksheets
      if spreadsheet.mapping['worksheets']

        spreadsheet.mapping['worksheets'].each do |worksheet_mapping|
          puts '--------------------'
          puts worksheet_mapping.class.name
          puts worksheet_mapping.inspect
          title = worksheet_mapping['title']
          worksheet = @loader.load_worksheet_from_spreadsheet spreadsheet, title
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
        @dependency_graph.add_dependency worksheet, associations
      end 

      # Convert the worksheets
      @dependency_graph.resolved_dependencies.each do |worksheet|
        WorksheetConverter.new(@model_store).convert(worksheet)
      end
    end
  end
end
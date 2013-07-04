module DriveTime

  class SpreadsheetConverter

    def initialize(model_store)
      @dependency_graph = DeepEnd::Graph.new
      @model_store = model_store
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
        @dependency_graph.add_dependency worksheet, associations
      end 
      # Convert the worksheets
      @dependency_graph.resolved_dependencies.each{|worksheet| WorksheetConverter.new(@model_store).convert(worksheet) }
    end
  end
end
module DriveTime

  class SpreadsheetsConverter
    require 'active_support/inflector'

    def initialize()
      Logger.info 'Beginning Spreadsheet Conversion'
      @dependency_graph = DeepEnd::Graph.new
      @loader = DriveTime::SpreadsheetLoader.new
      @model_store = ModelStore.new
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
          @dependency_graph.add_dependency spreadsheet, dependencies
        end

        # Now that dependencies are checked and ordered, convert load Worksheets
        @dependency_graph.resolved_dependencies.each{|spreadsheet| SpreadsheetConverter.new spreadsheet, @model_store }
      end
  end
  
end
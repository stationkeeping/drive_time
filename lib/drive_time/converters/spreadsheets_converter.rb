module DriveTime
  
  require 'active_support/inflector'
  require 'active_support/core_ext/hash'

  class SpreadsheetsConverter

    def initialize()
      @dependency_graph = DeepEnd::Graph.new
      @loader = DriveTime::SpreadsheetLoader.new
      @model_store = ModelStore.new
    end

    # Load mappings YML file
    def load(mappings_path)
      @mappings = ActiveSupport::HashWithIndifferentAccess.new(YAML::load File.open(mappings_path))
      convert
    end

    protected

      def convert
          spreadsheets = order_spreadsheets_by_dependencies(download_spreadsheets)
          # Now that dependencies are checked and ordered, convert load Worksheets
          spreadsheets.each{|spreadsheet| SpreadsheetConverter.new(@model_store, @loader).convert(spreadsheet) }
      end

      def download_spreadsheets
        spreadsheets = []
        # First download the spreadsheets
        @mappings[:spreadsheets].each do |spreadsheet_mapping|
          spreadsheet =  @loader.load_spreadsheet(spreadsheet_mapping[:title])
          raise "No spreadsheet with a title: #{spreadsheet_mapping['title']} available" if spreadsheet.nil?
          # Store mapping on the spreadsheet
          spreadsheet.mapping = spreadsheet_mapping
          spreadsheets << spreadsheet
        end
        return spreadsheets
      end

      def order_spreadsheets_by_dependencies(spreadsheets)
        # Now sort their dependencies before converting them
        spreadsheets.each do |spreadsheet|
          dependencies = []
          mapped_dependencies = spreadsheet.mapping[:dependencies]
          if mapped_dependencies
            # Run through each dependency
            mapped_dependencies.each do |dependency_title|
              # And find the spreadsheet which satisfies it
              matched_item = spreadsheets.find { | spreadsheet | spreadsheet.title == dependency_title }
              dependencies << matched_item if matched_item
              raise "Missing spreadsheet dependency #{spreadsheet.mapping['title']} needs #{dependency_title}" if dependencies.count < mapped_dependencies.count
            end
          end
          @dependency_graph.add_dependency spreadsheet, dependencies
        end
        return @dependency_graph.resolved_dependencies
      end

  end
end
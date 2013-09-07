module DriveTime

  class SpreadsheetConverter

    class MissingAssociationError < StandardError; end

    def initialize(model_store, loader, namespace=nil)
      @dependency_graph = DeepEnd::Graph.new
      @class_name_map = ClassNameMap.new
      @model_store = model_store
      @loader = loader
      @namespace = namespace
    end

    def convert(spreadsheet)
      @spreadsheet = spreadsheet

      spreadsheet.mapping[:worksheets].each do |worksheet|
        class_name = DriveTime.class_name_from_title(worksheet[:title])
        mapped_class_name = worksheet[:map_to_class]
        @class_name_map.save_mapping(class_name, mapped_class_name)
      end

      worksheets = order_worksheets_by_dependencies( load_worksheets spreadsheet.mapping[:worksheets] )
      # Convert the worksheets
      worksheets.each do |worksheet|
        WorksheetConverter.new(@model_store, @class_name_map, @loader, @namespace).convert(worksheet)
      end

      @model_store.save_all
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
      puts "name: #{name}"
      #puts 'NAME '+name
      # And find the worksheet that satisfies it
      worksheets.each do |worksheet|
        class_name = DriveTime.class_name_from_title(worksheet.title)
        resolved = @class_name_map.resolve_mapped_from_original class_name
        #puts '***********'+ resolved
        # If the name matches we have a dependent relationship
        puts "++++++++ #{resolved.underscore}"
        if resolved.underscore == name
          return worksheet
        end
      end
      raise MissingAssociationError, "No worksheet #{name} to satisfy multi association"
    end

  end
end

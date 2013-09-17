module DriveTime

  class SpreadsheetMapping

    def initialize(mapping, class_map)
      @mapping = mapping
      @class_map = class_map
      # Set default if not included in mapping
      @mapping[:worksheets] ||= []
    end

    def title
      @mapping[:title]
    end

    def worksheets
      @worksheets ||= build_worksheets
    end

    protected

    def build_worksheets
      validator = WorksheetMappingValidator.new
      @worksheets = @mapping[:worksheets].map do |worksheet|
        WorksheetMapping.new(worksheet, @class_map, validator).validate
      end
    end

  end
end


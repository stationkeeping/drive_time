module DriveTime

  class SpreadsheetMapping

    def initialize(mapping, class_map)
      @mapping = mapping
      @class_map = class_map
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
      if @mapping[:worksheets]
        @worksheets = @mapping[:worksheets].map do |worksheet|
          WorksheetMapping.new(worksheet, @class_map, validator).validate
        end
      else
        []
      end
    end

  end
end


module DriveTime

  class GoogleDriveMapping

    def initialize(mapping)
      @mapping = mapping
      @class_map = ClassMap.new
    end

    def title
      @mapping[:title]
    end

    def spreadsheets
      @spreadsheets ||= build_spreadsheets
    end

    protected

    def build_spreadsheets
      if @mapping[:spreadsheets]
         @mapping[:spreadsheets].map{|spreadsheet| SpreadsheetMapping.new(spreadsheet, @class_map)}
      else
        []
      end
    end

  end
end
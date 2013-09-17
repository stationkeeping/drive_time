module DriveTime

  class GoogleDriveMapping

    def initialize(mapping)
      @mapping = mapping
      @class_map = ClassMap.new
      @mapping[:spreadsheets] ||= []
    end

    def title
      @mapping[:title]
    end

    def spreadsheets
      @spreadsheets ||= build_spreadsheets
    end

    protected

    def build_spreadsheets
      @mapping[:spreadsheets].map{|spreadsheet| SpreadsheetMapping.new(spreadsheet, @class_map)}
    end

  end
end
module DriveTime
  
    # Load a Spreadsheet from Google Drive
  class SpreadsheetLoader

    def initialize
      @session = GoogleDrive.login( ENV['GOOGLE_USERNAME'], ENV['GOOGLE_PASSWORD'])
    end

    def load(title)
      spreadsheet = @session.spreadsheet_by_title(title)
      raise "Spreadsheet #{title} not found" if spreadsheet.nil?
      return spreadsheet
    end

  end

end
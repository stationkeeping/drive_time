require 'json'

module DriveTime

  # Currently assumes a Spreadsheet with a single Worksheet
  class GoogleSpreadsheetExpander

    attr_reader :key

    def initialize(loader)
      @loader = loader
      @key = 'spreadsheet'
    end

    def expand(filename)
      spreadsheet = @loader.load_spreadsheet_direct(filename)
      if spreadsheet.blank?
        raise TokenExpansionError, "Missing spreadsheet named: #{filename}"
      end
      # Use first Worksheet
      worksheet = spreadsheet.worksheets[0]
      expand_worksheet(worksheet)
    end

    def expand_worksheet(worksheet)
      rows = worksheet.rows.dup
      # Take the first row which will be the column names and use the cell value as the field name
      fields = rows.shift.map{ |row|  row[/\w+/] }
      instances = []
      # Reject rows of only empty strings (empty cells).
      rows.reject! {|row| row.all?(&:empty?)}
      rows.each do |row|
        key_value_pairs = [fields.dup, row.dup].transpose
        hash = Hash[*key_value_pairs.flatten]
        instances.push(hash)
      end
      root = {objects: instances }
      return root.to_json.to_s
    end

  end
end

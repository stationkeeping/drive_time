module DriveTime

	class FieldExpander

    class TokenExpansionError < StandardError; end

    def initialize(loader)
    	@loader = loader
    end

		def expand(value, model_key)
			filename = model_key
			# Check for token
      match = /\[(.*?)\]/.match(value)
      # Expand token into file
      # Is there a different filename defined in hard brackets [file_name]
      if match
          filename = match[1]
          value = value.split('[').first
      end

      puts 'Filename > '+filename.inspect
      puts 'Token > '+value.inspect

      if value == 'expand_file'
        file = @loader.load_file_direct(filename+'.txt');
        if file.blank?
          raise TokenExpansionError, "Missing file named: #{filename} when expanding from value: #{value} in model: #{model_key}"
        end
        value = expand_file(file)
      elsif value == 'expand_spreadsheet'
        spreadsheet = @loader.load_spreadsheet_direct(filename)
        if spreadsheet.blank?
          raise TokenExpansionError, "Missing spreadsheet named: #{filename} when expanding from value: #{value} in model: #{model_key}"
        end
        # Use first Worksheet
        worksheet = spreadsheet.worksheets[0]
        value = expand_worksheet(worksheet)
      else
        raise TokenExpansionError, "Don't know how to expand the value #{value} for model: #{model_key}"
      end
      puts 'Returned < '+value.inspect
      return value
    end

    # Build a JSON object from the columns
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

    def expand_file(file)
      return file.download_to_string()
    end

	end

end
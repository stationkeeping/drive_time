module DriveTime

  class WorksheetSource

    def initialize(worksheet, expander)
      @worksheet = worksheet
      @expander = expander
    end

    def mapping
      @worksheet.mapping
    end

    def model_definitions()
      rows = @worksheet.rows.dup
      # Remove the first row and use it for field-names
      field_names = rows.shift.map{ |row| row }
      # Reject rows of only empty strings (empty cells).
      rows.reject! {|row| row.all?(&:empty?)}
      rows.map do |row|
        build_definition(field_names, row)
      end
    end

    protected

    # Convert source row into hash
    def build_definition(field_names, row)
      model_definition = HashWithIndifferentAccess.new
      Logger.log_as_sub_header "Mapping fields to cells"
      row.dup.each_with_index do |cell, index|
        # Sanitise
        field_name = DriveTime.underscore_from_text(field_names[index])
        Logger.debug "- #{field_name} -> #{row[index]}"
        field_value = row[index]
        field_value.strip! if field_value.present?
        model_definition[field_name] = field_value
      end
      return ModelDefinition.new(model_definition, mapping, @expander)
    end

  end
end
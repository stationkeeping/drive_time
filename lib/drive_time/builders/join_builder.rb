module DriveTime

  # Take a series of name fields. Look up their values and assemble them into a single id
  # For example it might build a name from a model's title and its amount
  class JoinBuilder

    class MissingFieldError < StandardError; end
    class NoFieldsError < StandardError; end

    # Fields to use for names
    def build(field_keys, row_map)
      values = []

      field_keys.each do |field_key|
        raise MissingFieldError, "No field for key #{field_key}" if !row_map.has_key? field_key
        values << DriveTime.underscore_from_text(row_map[field_key]) unless row_map[field_key].empty?
      end

      raise NoFieldsError, 'No fields matched' if values.empty?

      values.each_with_index do |value, index|

        result = self.process_value value
        if result
          values[index] = result
        end
      end
      values.join('_').downcase
    end

    protected

    def process_value(value)
      return value
    end

  end

end

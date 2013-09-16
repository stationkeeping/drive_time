module DriveTime

  # Take a series of name fields. Look up their values and assemble them into a single id
  # For example it might build a name from a model's title and its amount
  class JoinBuilder

    def build(field_keys, model_definition)
      values = []

      field_keys.each do |field_key|
        values << DriveTime.underscore_from_text(model_definition.value_for(field_key)) if model_definition.has_value_for?(field_key)
      end

      raise NoFieldsError, "No fields matched" if values.empty?

      values.each_with_index do |value, index|
        result = self.process_value value
        if result
          values[index] = result
        end
      end
      values.join("_").downcase
    end

    protected

    def process_value(value)
      return value
    end

  end
end

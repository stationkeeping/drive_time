module DriveTime

  # Take a series of name fields. Look up their values and assemble them into a single id
  class NameBuilder

    class MissingFieldError < StandardError; end
    class NoFieldsError < StandardError; end

    # Fields to use for names
    def self.build(name_field_keys, row_map)
      names = []

      name_field_keys.each do |name_key|
        raise MissingFieldError, "No field for key #{name_key}" if !row_map.has_key? name_key     
        names << DriveTime.underscore_from_text(row_map[name_key]) if row_map[name_key].present?
      end

      raise NoFieldsError, 'No fields matched' if names.empty?

      names.each_with_index do |name, index|
        # Add a period to initials
        if name.length == 1
          names[index] = "#{name}."
        end
      end
      names.join('_').downcase
    end
  end

end
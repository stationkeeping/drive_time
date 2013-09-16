module DriveTime

  class WorksheetMappingValidator

    def validate(mapping)
      methods.grep(/^validate_/).each do |m|
         send(m,mapping)
      end
      mapping
    end

    protected

    def validate_presence_of_title(mapping)
      raise ValidationError, "Worksheet Mapping must declare a title." unless mapping.title
    end

    def validate_presence_of_key(mapping)
      raise ValidationError, "Worksheet Mapping must declare a key." unless mapping.key
    end

    def validates_class_exists(mapping)
      begin
        mapping.clazz
      rescue Exception
        raise ValidationError, "Worksheet Mapping Class doesn't exist."
      end
    end

  end
end
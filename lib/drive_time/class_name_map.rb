module DriveTime

  class ClassNameMap

    def initialize
      @map = BiDirectionalHash.new
    end

    # Check for mapped class
    def resolve_original_from_mapped(className)
      if @map.has_key_for_value className
        @map.key_for_value className
      else
        className
      end
    end

    def resolve_mapped_from_original(className)
      if @map.has_value_for_key className
        @map.value_for_key className
      else
        className
      end
    end

    def save_mapping(class_name, mapped_class_name)

      if mapped_class_name
        # Save mapping so we can look it up from both directions
        @map.insert(class_name, mapped_class_name)
        mapped_class_name
      else
        class_name
      end
    end

  end

end

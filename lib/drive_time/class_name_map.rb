module DriveTime

  # This is a fluid two-way map. In both directions it will return a mapping if it exists, otherwise
  # it will return the value passed to it. It does not raise an exception if a mapping is not found.
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

    # Accepts String versions of class names eg. ExampleClass
    def save_mapping(class_name, mapped_class_name=nil)
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

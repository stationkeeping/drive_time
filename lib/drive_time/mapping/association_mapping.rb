module DriveTime

  class AssociationMapping

    def initialize(mapping, class_map)
      @mapping = mapping
      @class_map = class_map
    end

    def name
      @mapping[:name]
    end

    def clazz
      mapping = @class_map.mapping_for_class(DriveTime.class_name_from_title(name))
      if mapping
        mapping.constantize
      else
        name.constantize
      end
    end

    # Handle possible polymorphic association
    # If name is an array, we need to add each possibility as a dependency
    def names
      if is_polymorphic?
        @mapping[:names]
      else
        [name]
      end
    end

    def attribute_names
      @mapping[]
    end

    def is_polymorphic?
      polymorphic.present?
    end

    def is_required?
      @mapping[:required] == true
    end

    def is_optional?
      @mapping[:optional] == true
    end

    def is_singular?
      @mapping[:singular] == true
    end

    def is_inverse?
      @mapping[:inverse] == true
    end

    def polymorphic
      @mapping[:polymorphic]
    end

    def builder
      @mapping[:builder]
    end

    def attribute_names
      @mapping[:attribute_names]
    end

  end
end

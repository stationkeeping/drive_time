module DriveTime

  class AssociationMapping

    def initialize(mapping, class_map)
      @mapping = mapping
      @class_map = class_map
    end

    def name
      @mapping[:name]
    end

    def as
      @mapping[:as]
    end

    def clazz
      @clazz ||= build_class
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

    def source
      @mapping[:source]
    end

    def through?
      @mapping[:through].present?
    end

    def through_as
     @mapping[:through][:as]
    end

    def through_class
      @mapping[:through][:class] if through?
    end

    def through_attributes
      @mapping[:through][:attributes] if through?
    end

    def through_is_polymorphic?
      self.through_as.present?
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

    def is_polymorphic?
      polymorphic.present?
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

    protected

    def build_class
      class_name = @class_map.mapping_for_class(class_name) || DriveTime.class_name_from_title(name)
      @clazz = class_name.constantize
    end

  end
end

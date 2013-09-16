module DriveTime

  class WorksheetMapping

    def initialize(mapping, class_map, validator=nil)
      @mapping = mapping
      @class_map = class_map
      @validator = validator
    end

    def validate
      @validator.validate(self)
    end

    def title
      @mapping[:title]
    end

    def clazz
      @clazz ||= build_class
    end

    def mapped_class
      @mapping[:map_to_class]
    end

    def attributes
      @attributes ||= @mapping[:attributes] || []
    end

    def associations
      @associations ||= build_associations
    end

    def calls
      @calls ||= @mapping[:calls] || []
    end

    def key
      @mapping[:key]
    end

    def key_to
      @mapping[:key_to]
    end

    def association_names

    end

    protected

    def build_associations
      if @mapping[:associations]
        @mapping[:associations].map{ |association| AssociationMapping.new(association, @class_map) }
      else
        []
      end
    end

    def build_class
      if mapped_class
        @class_map.map_class(DriveTime.class_name_from_title(title), mapped_class)
      end
      class_name = mapped_class || DriveTime.class_name_from_title(title)
      begin
        @clazz = class_name.constantize
      rescue StandardError => error
        raise NoClassError, "No class exists for #{class_name}. #{error}"
      end
    end

  end
end
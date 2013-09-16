module DriveTime

  class ClassMap

    def initialize()
      @class_map = {}
    end

    def mapping_for_class(clazz)
      @class_map[clazz]
    end

    def map_class(clazz, to_clazz)
      @class_map[clazz] = to_clazz
    end
  end
end

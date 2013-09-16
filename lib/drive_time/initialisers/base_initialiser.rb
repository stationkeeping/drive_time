module DriveTime

  class BaseInitialiser

    def initialize()
      @dependency_graph = DeepEnd::Graph.new
      @expander = FieldExpander.new
      @model_store = ModelStore.new(DriveTime::log_level)
    end

    # Load mappings YML file
    def load(mappings_path)
      mappings = ActiveSupport::HashWithIndifferentAccess.new(YAML::load(File.open(mappings_path)))
      aquire_source(mappings)
    end

    def save_models
      @model_store.save_all
      Logger.log_as_header "Conversion Complete. Woot Woot."
    end

    protected

    def aquire_source(mappings)
      raise 'This method must be implemented in subclasses'
    end

  end
end
module DriveTime

  # Store model instances by class and link
  # This way we can look them up as needed to
  # satisfy dependencies and avoid duplication
  class ModelStore

    # Errors
    class NoModelsOfClassInStoreError < StandardError; end
    class NoModelOfClassWithKeyInStoreError < StandardError; end
    class ModelAddedTwiceError < StandardError; end

    def initialize
      @store = {}

      # Set up logging
      formatter = Log4r::PatternFormatter.new(:pattern => "[%c] %M")
      outputter = Log4r::Outputter.stdout
      outputter.formatter = formatter

      @logger = Log4r::Logger.new 'model_store'
      @logger.outputters = outputter
    end

    # Store the model by class to avoid key collisions
    def add_model(instance, key, clazz)
      class_string = clazz.to_s
      puts " ---> Adding Model of class #{clazz}"
      # Sanitise key
      key = DriveTime.underscore_from_text(key)
      @logger.info "Adding model with key #{key} of class #{clazz}"
      if !@store[class_string]
        @store[class_string] = {}
      elsif @store[class_string][key]
        raise ModelAddedTwiceError, "#{instance} has already been added to model store"
      end
      @store[class_string][key] = instance
    end

    def get_model(clazz, key)
      puts " ---> Getting Model of class #{clazz.to_s}"
      @logger.info "Requested model with key #{key} of class #{clazz}"

      models_for_class = @store[clazz.to_s]
      puts models_for_class.inspect
      # Are there any classes of this type in the store?
      if models_for_class.nil?
        raise NoModelsOfClassInStoreError, "No classes of type: #{clazz} in model store"
      end

      # Is there an instance
      model = models_for_class[key]

      if !model
        raise NoModelOfClassWithKeyInStoreError, "No model of class #{clazz} with a key of #{key} in model store"
      end

      return model
    end

    def save_all
      @logger.info "Saving models "
      @store.each do |key, models|
        @logger.info "-- Of Type: '#{key}'"
        models.each do |key, model|
          @logger.info "---- Model: #{model.inspect}"
          model.save!
        end
      end
    end

  end

end

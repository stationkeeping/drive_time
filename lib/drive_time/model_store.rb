require "log4r"

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
    def add_model(instance, key)
      # Sanitise key
      key = DriveTime.underscore_from_text(key)
      clazz = instance.class.to_s
      @logger.info "Adding model with key #{key} of class #{instance.class.to_s}"
      if !@store[clazz]
        @store[clazz] = {} 
      elsif @store[clazz][key]
        raise ModelAddedTwiceError, "#{instance} has already been added to model store" 
      end
      @store[clazz][key] = instance
    end

    def get_model(clazz, key)
      @logger.info "Requested model with key #{key} of class #{clazz}"

      models_for_class = @store[clazz.to_s]
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

  end

end
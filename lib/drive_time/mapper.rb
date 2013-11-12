require "securerandom"

module DriveTime

  class Mapper

    class NoFieldNameError < StandardError; end
    class NoMethodError < StandardError; end
    class NoKeyError < StandardError; end
    class PolymorphicAssociationError < StandardError; end

    def initialize(model_store)
      @model_store = model_store
    end

    def convert(model_definition)
      @model_definition = model_definition
      generate_model
    end

    protected

    def generate_model
      Logger.log_as_header("Generating '#{@model_definition.mapping.clazz.name}' Model with key: '#{@model_definition.key}'")
      # If a model_definition has been marked as not complete, ignore it
      if @model_definition.is_complete?
        Logger.debug("Row marked as not complete. Ignoring")
        return
      end
      Logger.debug(" - Attributes: '#{@model_definition.attributes.inspect}'")
      # Create new model
      @model = @model_definition.mapping.clazz.new(@model_definition.attributes, without_protection: true)
      invoke_methods_on_model(@model_definition.method_calls)
      # Add its associations
      add_associations
      # Store the model using its ID
      puts @model, @model_definition.key, @model_definition.mapping.clazz
      @model_store.add_model(@model, @model_definition.key, @model_definition.mapping.clazz)
    end

    def add_associations
      Logger.log_as_sub_header("Adding associations to model")
      # Loop through any associations defined in the mapping for this model
      @model_definition.mapping.associations.each do |association_mapping|
        # Use the spreadsheet name unless 'map_to_class' is set
        unless association_mapping.is_polymorphic?
          association_class = association_mapping.clazz
        else
          # The classname will be taken from the type collumn
          association_class = @model_definition.type
        end
        # Assemble associated model instances to satisfy this association
        associated_models = gather_associated_models(association_mapping, association_class)
        set_associations_on_model(associated_models, association_mapping, association_class)
      end
    end

    def gather_associated_models(association_mapping, association_class)
      associated_models = []
      if association_mapping.builder
        associated_models = associated_models_from_builder(association_mapping, association_class)
      else # It's a single text value, so convert it to an ID
        unless association_mapping.is_polymorphic?
          association_id = @model_definition.value_for(association_mapping.name.underscore)
        else
          association_id = @model_definition.value_for(association_mapping.polymorphic[:association])
        end
        raise MissingAssociationError, "No attribute: '#{association_mapping.name.underscore}' to satisfy association." if !association_id
        if association_id.length > 0 || association_mapping.is_required?
          associated_models << model_for_id(association_id, association_class)
        end
      end
      return associated_models
    end

    def associated_models_from_builder(association_mapping, association_class)
      associated_models = []
      if association_mapping.builder == "multi" # It's a multi value, find a matching cell and split its value by comma
        # Use only the classname for the attributename unless source has been set
        field_name = association_mapping.source || association_class.to_s.underscore.pluralize
        cell_value = @model_definition.value_for(field_name)
        raise MissingAssociationError, "No field '#{field_name}'' to satisfy multi association." if cell_value.blank? && !association_mapping.is_optional?
        components = MultiBuilder.new.build(cell_value)
        components.each do |component|
            associated_models << model_for_id(component, association_class)
        end
      elsif association_mapping.builder == "use_attributes" # Use column names as values if cell contains 'yes' or 'y'
        association_mapping.attribute_names.each do |attribute_name|
          cell_value = @model_definition.value_for(attribute_name)
          if DriveTime.is_affirmative? cell_value
            associated_models << model_for_id(attribute_name, association_class)
          end
        end
      end
      return associated_models
    end

    def invoke_methods_on_model(method_calls)
      # Invoke any method calls
      method_calls.each do |method_call|
        call_step = @model
        methods = method_call["methods"]

        methods.each_with_index do |method, index|
          if index == method_call.length - 1
            call_step.send(method, method_call["value"])
          else
            call_step = call_step.send(method)
          end
        end
      end
    end

    def set_associations_on_model(associated_models, association_mapping, association_class)
      # We now have one or more associated_models to set as associations on our model
      associated_models.each do |associated_model|
        Logger.debug(" - Associated Model: '#{associated_model}'")
        unless association_mapping.is_inverse?
          association_name = association_class.to_s.demodulize.underscore
          if association_mapping.is_singular?
            Logger.debug("   - Adding association '#{associated_model}' to '#{@model}', '#{association_name}'")
            # This a temporary fix for theme_id being set to nil on assignment and save.
            # Is this a bug or do I need to rethink saving at the end. It might be that each model
            # needs to be saved on creation so that it has an id
            associated_model.save!
            # Set the association
            @model.send("#{association_name}=", associated_model)
          else
            if association_mapping.through?
              if association_mapping.through_is_polymorphic?
                attributes = association_mapping.through_attributes.merge({"#{association_mapping.through_as}" => @model, "#{associated_model.class.name.underscore}" => associated_model})
              else
                attributes = association_mapping.through_attributes.merge({"#{@model.class.name.underscore}" => @model, "#{associated_model.class.name.underscore}" => associated_model})
              end
              through_model = association_mapping.through_class.constantize.new(attributes);
              # Add the model to the store so it is saved
              @model_store.add_model(through_model, SecureRandom.uuid, through_model.class);
            else
              association_name = association_name.pluralize
              model_associations = @model.send(association_name)
              Logger.debug("   - Adding association '#{associated_model}' to '#{@model}', '#{association_name}'")
              # Push the association
              model_associations << associated_model
            end
          end
        else # The relationship is actually inverted, so save the model as an association on the associated_model
          model_name = @model.class.name.demodulize.underscore
          if association_mapping.is_singular?
            Logger.debug("   - Adding association '#{@model}' to '#{associated_model}', '#{association_name}'")
            associated_model.send(model_name, @model)
          else
            model_name = model_name.pluralize
            model_associations = associated_model.send model_name
            Logger.debug("   - Adding association '#{@model}' to '#{associated_model}', '#{model_name}'")
            model_associations << @model
          end
        end
      end
    end

    def model_for_id(value, clazz)
      key = DriveTime.underscore_from_text(value)
      return @model_store.get_model(clazz, key)
    end

  end
end

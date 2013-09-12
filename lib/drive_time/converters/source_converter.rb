module DriveTime

  class SourceConverter

    class NoClassWithTitleError < StandardError; end
    class NoFieldNameError < StandardError; end
    class NoMethodError < StandardError; end
    class NoKeyError < StandardError; end
    class PolymorphicAssociationError < StandardError; end

    def initialize(model_store, class_name_map, expander, namespace)
      @class_name_map = class_name_map
      @model_store = model_store
      @namespace = namespace
      @expander = expander
    end

    # A source needs a title, a mapping and a models_source propery
    def convert(source)
      @source = source
      Logger.log_as_header "Converting source: #{@source.mapping[:title]}"
      # Use the spreadsheet name unless 'map_to_class' is set
      class_name = DriveTime.class_name_from_title(@source.mapping[:title])
      class_name = @class_name_map.resolve_mapped_from_original(class_name)
      Logger.debug "Converting @source #{@source.mapping[:title]} to class #{class_name}"
      # Check class exists - better we know immediately
      begin
        clazz = DriveTime.namespaced_class_name(class_name, @namespace)
      rescue StandardError => error
        raise NoClassWithTitleError, "Source named #{@source.mapping[:title]} doesn't exists as class #{class_name}"
      end
      @source.model_definitions.each { |model_defnition| generate_model(model_defnition, clazz) }
    end

    protected

    def generate_model(model_definition, clazz)
      Logger.log_as_header "Converting model_definition to class: #{clazz.name}"

      # If a model_definition has been marked as not complete, ignore it
      if model_definition[:complete] == 'No'
        Logger.debug 'Row marked as not complete. Ignoring'
        return
      end

      model_key = build_id_for_model(model_definition)
      Logger.log_as_sub_header "Model Key: #{model_key}"
      # Build hash ready to pass into model
      model_attributes = model_definition_to_model_attributes(model_definition, model_key)
      method_calls = model_definition_to_method_calls(model_definition, model_key)

      # Set the model key as an attribute on the model
      if @source.mapping[:key_to]
        model_attributes[mapping[:key_to]] = model_key
      end

      Logger.debug "Creating Model of class '#{clazz.name.to_s}' with Model Fields #{model_attributes.to_s}"

      # Create new model
      model = clazz.new(model_attributes, without_protection: true)
      invoke_methods_on_model(model, method_calls)

      # Add its associations
      add_associations(model, model_definition)
      # Store the model using its ID
      @model_store.add_model(model, model_key, clazz)
    end

    def invoke_methods_on_model(model, method_calls)
      # Invoke any method calls
      method_calls.each do |method_call|
        call_step = model
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

    def model_definition_to_method_calls(model_definition, model_key)
      method_calls = []
      # Run through the mapping, pulling values from model_definition as required
      if @source.mapping[:calls]
        @source.mapping[:calls].each do |call_mapping|
          attribute_name = call_mapping[:name]
          methods = call_mapping[:methods]

          unless methods
            raise NoMethodError "Missing Method: Name for call attribute: #{attribute_name} in mapping: #{mapping}"
          end

          attribute_value = parse_attribute_value(model_definition[attribute_name], model_key)

          # handle multi-values
          if call_mapping[:builder] == "multi"
            attribute_value = MultiBuilder.new.build(attribute_value)
          end
          method_calls << {"methods" => methods, "value" => attribute_value}
        end
      end
      return method_calls
    end

    # Run through the mapping's attributes and convert them
    def model_definition_to_model_attributes(model_definition, model_key)
      model_attributes = HashWithIndifferentAccess.new

      # Run through the mapping, pulling values from model_definition as required
      if @source.mapping[:attributes]
        @source.mapping[:attributes].each do |attribute_mapping|
          attribute_name = attribute_mapping[:name]
          mapped_to_attribute_name = attribute_mapping[:map_to]

          unless attribute_name
            raise NoFieldNameError "Missing Field: Name for attribute: #{value} in mapping: #{mapping}"
          end

          attribute_value = parse_attribute_value(model_definition[attribute_name], model_key)
          model_attributes[mapped_to_attribute_name || attribute_name] = attribute_value
        end
      end
      return model_attributes
    end

    def add_associations(model, model_definition)
      associations_mapping = @source.mapping[:associations]
      if associations_mapping
        Logger.log_as_sub_header "Adding associations to model "

        # Loop through any associations defined in the mapping for this model
        associations_mapping.each do |association_mapping|
          # Use the spreadsheet name unless 'map_to_class' is set
          if !association_mapping[:polymorphic]
            association_class_name = @class_name_map.resolve_mapped_from_original(association_mapping[:name].classify)
          else
            possible_class_names = association_mapping[:name]
            # The classname will be taken from the type collumn
            association_class_name = DriveTime.class_name_from_title(model_definition[:type])
            # if !possible_class_names.include? association_class_name.underscore
            #     raise PolymorphicAssociationError, "Mapping for polymorphic associations: #{possible_class_names.inspect} doesn't include #{association_class_name}"
            # end
          end
          # Get class reference using class name
          begin
            clazz = DriveTime.namespaced_class_name(association_class_name, @namespace)
          rescue
            raise NoClassWithTitleError, "Association defined in source doesn't exist as class: #{association_class_name}"
          end

          # Assemble associated model instances to satisfy this association
          associated_models = gather_associated_models(association_mapping, association_class_name, clazz, model_definition)
          set_associations_on_model(model, associated_models, association_mapping, association_class_name)
        end
      end
    end

    def gather_associated_models(association_mapping, association_class_name, clazz, model_definition)
      associated_models = []
      if association_mapping[:builder]
        associated_models = associated_models_from_builder association_mapping, association_class_name, model_definition
      else # It's a single text value, so convert it to an ID
        association_class = @class_name_map.resolve_original_from_mapped(association_class_name).underscore
        if !association_mapping[:polymorphic]
          association_id = model_definition[association_class]
        else
          association_id = model_definition[association_mapping[:polymorphic][:association]]
        end
        raise MissingAssociationError, "No attribute #{association_class_name.underscore} to satisfy association" if !association_id
        if association_id.length > 0 || association_mapping[:required] == true
          associated_models << model_for_id(association_id, clazz)
        end
      end
      return associated_models
    end

    def set_associations_on_model(model, associated_models, association_mapping, association_class_name)
      # We now have one or more associated_models to set as associations on our model
      associated_models.each do |associated_model|
        Logger.debug " - Associated Model: #{associated_model}"
        unless association_mapping[:inverse] == true
          association_name = association_class_name.demodulize.underscore
          if association_mapping[:singular] == true
            Logger.debug "   - Adding association #{associated_model} to #{model}::#{association_name}"
            # Set the association
            model.send("#{association_name}=", associated_model)
          else
            association_name = association_name.pluralize
            model_associations = model.send(association_name)
            Logger.debug "   - Adding association #{associated_model} to #{model}::#{association_name}"
            # Push the association
            model_associations << associated_model
          end
        else # The relationship is actually inverted, so save the model as an association on the associated_model
          model_name = model.class.name.demodulize.underscore
          if association_mapping[:singular] == true
            Logger.debug "   - Adding association #{model} to #{associated_model}::#{association_name}"
            associated_model.send model_name, model
          else
            model_name = model_name.pluralize
            model_associations = associated_model.send model_name
            Logger.debug "   - Adding association #{model} to #{associated_model}::#{model_name}"
            model_associations << model
          end
        end
      end
    end

    def associated_models_from_builder(association_mapping, class_name, model_definition)
      associated_models = []
      if association_mapping[:builder] == 'multi' # It's a multi value, find a matching cell and split its value by comma
        # Use only the classname for the attributename, discarding namespace
        attribute_name = class_name.demodulize.underscore.pluralize
        cell_value = model_definition[attribute_name]
        raise MissingAssociationError, "No attribute #{class_name.underscore.pluralize} to satisfy multi association" if cell_value.blank? && association_mapping[:optional] != true
        components = MultiBuilder.new.build(cell_value)
        components.each do |component|
          associated_models << model_for_id(component, DriveTime.namespaced_class_name(class_name, @namespace))
        end
      elsif association_mapping[:builder] == 'use_attributes' # Use column names as values if cell contains 'yes' or 'y'
        association_mapping[:attribute_names].each do |attribute_name|
          cell_value = model_definition[attribute_name]
          if DriveTime.is_affirmative? cell_value
            associated_models << model_for_id(attribute_name, DriveTime.namespaced_class_name(class_name, @namespace))
          end
        end
      end
      return associated_models
    end

    def model_for_id(value, clazz)
      model_key = DriveTime.underscore_from_text value
      return @model_store.get_model clazz, model_key
    end

    def build_id_for_model(model_definition)
      raise NoKeyError, 'All mappings must declare a key' unless @source.mapping.has_key? :key
      key = @source.mapping[:key]
      if key.is_a? Hash
        id_from_builder(key, model_definition)
      else # If it's a string, it refers to an attribute
        key = model_definition[key]
        raise NoFieldNameError, "No field #{key} on source #{@source.mapping[:title]}" if !key
        DriveTime.underscore_from_text(key)
      end
    end

    def id_from_builder(key, model_definition)
      if key[:builder] == 'join'
        JoinBuilder.new.build key[:from_attributes], model_definition
      elsif key[:builder] == 'name'
        NameBuilder.new.build key[:from_attributes], model_definition
      else
        raise "No builder for key on source"
      end
    end

    def parse_attribute_value(attribute_value, model_key)
      if attribute_value
        attribute_value = check_for_token(attribute_value, model_key)
        attribute_value = DriveTime.check_string_for_boolean(attribute_value)
      end
      # Make sure any empty cells give us nil (rather than an empty string)
      attribute_value = nil if attribute_value.blank?
      attribute_value
    end

    def check_for_token(value, model_key)
      # Check for token pattern: {{some_value}}
      token = /\{\{(.*?)\}\}/.match(value)
      if token
        @expander.expand(token[1], model_key)
      else
        value
      end
    end


  end
end

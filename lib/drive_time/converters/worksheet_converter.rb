module DriveTime

  class WorksheetConverter

    attr_accessor :row_map

    class NoClassWithTitleError < StandardError; end
    class NoFieldNameError < StandardError; end
    class NoMethodError < StandardError; end
    class NoKeyError < StandardError; end
    class PolymorphicAssociationError < StandardError; end

    def initialize(model_store, class_name_map, loader, namespace)
      @class_name_map = class_name_map
      @model_store = model_store
      @loader = loader
      @namespace = namespace
      @field_expander = FieldExpander.new(@loader)
    end

    def convert(worksheet)
      Logger.log_as_header "Converting worksheet: #{worksheet.title}"
      # Use the spreadsheet name unless 'map_to_class' is set
      class_name = DriveTime.class_name_from_title(worksheet.title)
      class_name = @class_name_map.resolve_mapped_from_original(class_name)
      Logger.debug "Converting Worksheet #{worksheet.title} to class #{class_name}"
      # Check class exists - better we know immediately
      begin
        clazz = namespaced_class_name(class_name)
      rescue StandardError => error
        raise NoClassWithTitleError, "Worksheet named #{worksheet.title} doesn't exists as class #{class_name}"
      end
      rows = worksheet.rows.dup
      # Remove the first row and use it for field-names
      field_names = rows.shift.map{ |row| row }
      # Reject rows of only empty strings (empty cells).
      rows.reject! {|row| row.all?(&:empty?)}
      rows.each { |row| generate_model_from_row(clazz, worksheet.mapping, field_names, row) }
    end

    protected

    def generate_model_from_row(clazz, mapping, field_names, row)
      Logger.log_as_header "Converting row to class: #{clazz.name}"
      # Create a hash of field-names and row cell values
      build_row_map(field_names, row)

      # If a row has been marked as not complete, ignore it
      if @row_map[:complete] == 'No'
        Logger.debug 'Row marked as not complete. Ignoring'
        return
      end

      model_key = build_id_for_model(mapping)
      Logger.log_as_sub_header "Model Key: #{model_key}"
      # Build hash ready to pass into model
      model_fields = row_fields_to_model_fields(mapping, model_key)
      method_calls = row_fields_to_method_calls(mapping, model_key)

      # Set the model key as an attribute on the model
      if mapping[:key_to]
        model_fields[mapping[:key_to]] = model_key
      end

      Logger.debug "Creating Model of class '#{clazz.name.to_s}' with Model Fields #{model_fields.to_s}"

      # Create new model
      model = clazz.new(model_fields, without_protection: true)

      invoke_methods_on_model(model, method_calls)

      # Add its associations
      add_associations(model, mapping)
      # Store the model using its ID
      @model_store.add_model(model, model_key, clazz)
    end

    # Convert worksheet row into hash
    def build_row_map(field_names, row)
      @row_map = HashWithIndifferentAccess.new
      Logger.log_as_sub_header "Mapping fields to cells"
      row.dup.each_with_index do |cell, index|
        # Sanitise
        field_name = DriveTime.underscore_from_text(field_names[index])
        Logger.debug "- #{field_name} -> #{row[index]}"
        field_value = row[index]
        field_value.strip! if field_value.present?
        @row_map[field_name] = field_value
      end
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

    def row_fields_to_method_calls(mapping, model_key)
      method_calls = []
      # Run through the mapping, pulling values from row_map as required
      if mapping[:calls]
        mapping[:calls].each do |call_mapping|
          field_name = call_mapping[:name]
          methods = call_mapping[:methods]

          unless methods
            raise NoMethodError "Missing Method: Name for call field: #{field_name} in mapping: #{mapping}"
          end

          field_value = parse_field_value(@row_map[field_name], model_key)

          # handle multi-values
          if call_mapping[:builder] == "multi"
            field_value = MultiBuilder.new.build(field_value)
          end
          method_calls << {"methods" => methods, "value" => field_value}
        end
      end
      return method_calls
    end

    # Run through the mapping's fields and convert them
    def row_fields_to_model_fields(mapping, model_key)
      model_fields = HashWithIndifferentAccess.new

      # Run through the mapping, pulling values from row_map as required
      if mapping[:fields]
        mapping[:fields].each do |field_mapping|
          field_name = field_mapping[:name]
          mapped_to_field_name = field_mapping[:map_to]

          unless field_name
            raise NoFieldNameError "Missing Field: Name for field: #{value} in mapping: #{mapping}"
          end

          field_value = parse_field_value(@row_map[field_name], model_key)
          model_fields[mapped_to_field_name || field_name] = field_value
        end
      end
      return model_fields
    end

    def add_associations(model, mapping)
      associations_mapping = mapping[:associations]
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
            association_class_name = DriveTime::class_name_from_title @row_map[:type]
            # if !possible_class_names.include? association_class_name.underscore
            #     raise PolymorphicAssociationError, "Mapping for polymorphic associations: #{possible_class_names.inspect} doesn't include #{association_class_name}"
            # end
          end
          # Get class reference using class name
          begin
            clazz = namespaced_class_name association_class_name
          rescue
            raise NoClassWithTitleError, "Association defined in worksheet doesn't exist as class: #{association_class_name}"
          end

          # Assemble associated model instances to satisfy this association
          associated_models = gather_associated_models(association_mapping, association_class_name, clazz)
          set_associations_on_model(model, associated_models, association_mapping, association_class_name)
        end
      end
    end

    def gather_associated_models(association_mapping, association_class_name, clazz)
      associated_models = []
      if association_mapping[:builder]
        associated_models = associated_models_from_builder association_mapping, association_class_name
      else # It's a single text value, so convert it to an ID
        association_class = @class_name_map.resolve_original_from_mapped(association_class_name).underscore
        if !association_mapping[:polymorphic]
          association_id = @row_map[association_class]
        else
          association_id = @row_map[association_mapping[:polymorphic][:association]]
        end
        raise MissingAssociationError, "No field #{association_class_name.underscore} to satisfy association" if !association_id
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

    def associated_models_from_builder(association_mapping, class_name)
      associated_models = []
      if association_mapping[:builder] == 'multi' # It's a multi value, find a matching cell and split its value by comma
        # Use only the classname for the fieldname, discarding namespace
        field_name = class_name.demodulize.underscore.pluralize
        cell_value = @row_map[field_name]
        raise MissingAssociationError "No field #{class_name.underscore.pluralize} to satisfy multi association" if cell_value.blank? && association_mapping[:optional] != true
        components = MultiBuilder.new.build(cell_value)
        components.each do |component|
          associated_models << model_for_id(component, namespaced_class_name(class_name))
        end
      elsif association_mapping[:builder] == 'use_fields' # Use column names as values if cell contains 'yes' or 'y'
        association_mapping[:field_names].each do |field_name|
          cell_value = @row_map[field_name]
          if DriveTime.is_affirmative? cell_value
            associated_models << model_for_id(field_name, namespaced_class_name(class_name))
          end
        end
      end
      return associated_models
    end

    def model_for_id(value, clazz)
      model_key = DriveTime.underscore_from_text value
      return @model_store.get_model clazz, model_key
    end

    def build_id_for_model(mapping)
      raise NoKeyError, 'All mappings must declare a key' unless mapping.has_key? :key
      key_node = mapping[:key]
      if key_node.is_a? Hash
        id_from_builder(key_node)
      else # If it's a string, it refers to a spreadsheet column
        key = @row_map[key_node]
        raise NoFieldNameError, "No column #{key_node} on worksheet #{mapping[:title]}" if !key
        DriveTime.underscore_from_text(key)
      end
    end

    def id_from_builder(key_node)
      if key_node[:builder] == 'join'
        JoinBuilder.new.build key_node[:from_fields], @row_map
      elsif key_node[:builder] == 'name'
        NameBuilder.new.build key_node[:from_fields], @row_map
      else
        raise "No builder for key on worksheet"
      end
    end

    def namespaced_class_name(class_name)
      class_name = "#{@namespace}::#{class_name}" unless @namespace.blank?
      class_name.constantize
    end

    def parse_field_value(field_value, model_key)
      if field_value
        field_value = check_for_token(field_value, model_key)
        field_value = check_for_boolean(field_value)
      end
      # Make sure any empty cells give us nil (rather than an empty string)
      field_value = nil if field_value.blank?
      field_value
    end

    def check_for_token(field_value, model_key)
      # Check for token pattern: {{some_value}}
      match = /\{\{(.*?)\}\}/.match(field_value)
      if match
        @field_expander.expand(match[1], model_key)
      else
        field_value
      end
    end

    def check_for_boolean(field_value)
      downcased = field_value.downcase
      if %w[y yes true].include? downcased
        true
      elsif %w[n no false].include? downcased
        false
      else
        field_value
      end
    end
  end
end

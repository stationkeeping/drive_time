module DriveTime

  class WorksheetConverter

    attr_accessor :row_map

    class NoClassWithTitleError < StandardError; end
    class NoFieldNameError < StandardError; end
    class MissingAssociationError < StandardError; end
    class NoKeyError < StandardError; end

    def initialize(model_store, name_class_map, loader)
      @name_class_map = name_class_map
      @model_store = model_store
      @loader = loader
      @field_expander = FieldExpander.new(@loader)
    end

    def convert(worksheet)
      puts '=============================================================================='
      puts 'CONVERTING WORKSHEET '+worksheet.title
      puts '=============================================================================='
      # Use the spreadsheet name unless 'map_to_class' is set
      class_name = DriveTime.class_name_from_title(worksheet.title)
      mapped_class_name = worksheet.mapping[:map_to_class]
      class_name = @name_class_map.save_mapping(class_name, mapped_class_name)
      Logger.info "Converting Worksheet #{worksheet.title} to class #{class_name}"
      # Check class exists - better we know immediately
      begin
        clazz = class_name.constantize
      rescue
        raise NoClassWithTitleError, "Worksheet named #{worksheet.title} doesn't exists as class #{class_name}"
      end
      rows = worksheet.rows.dup
      # Remove the first row and use it for field-names
      fields = rows.shift.map{ |row| row }
      # Reject rows of only empty strings (empty cells).
      rows.reject! {|row| row.all?(&:empty?)}

      rows.each do |row|
        generate_model_from_row clazz, worksheet.mapping, fields, row
      end
    end

    protected

      def generate_model_from_row(clazz, mapping, fields, row)
        puts '=============================================================================='
        puts 'CONVERTING ROW to '+clazz.name
        puts '=============================================================================='
        # Create a hash of field-names and row cell values
        build_row_map(fields, row)

        # If a row has been marked as not complete, ignore it
        if @row_map[:complete] == 'No'
          Logger.info 'Row marked as not complete. Ignoring'
          return
        end

        model_key = build_id_for_model mapping
        # Build hash ready to pass into model
        model_fields = row_fields_to_model_fields mapping, model_key

        # Set the model key as an attribute on the model
        if mapping[:key_to]
          puts '+++++++++'
          puts '+++++++++'
          puts '+++++++++'
          puts '+++++++++'
          puts '+++++++++'
          puts '+++++++++'
          puts mapping[:key_to]
          model_fields[mapping[:key_to]] = model_key
        end


        Logger.info "Creating Model of class #{clazz.name.to_s} with Model Fields #{model_fields.to_s}"
        # Create new model
        model = clazz.new(model_fields, without_protection: true)
        # Add its associations
        add_associations(model, mapping) 
        model.save!
        # Store the model using its ID
        @model_store.add_model model, model_key
      end

      # Convert worksheet row into hash
      def build_row_map(fields, row)
        @row_map = HashWithIndifferentAccess.new
        Logger.info "Mapping fields to cells"
        row.dup.each_with_index do |cell, index|
          # Sanitise
          field_name = DriveTime.underscore_from_text fields[index]
          @row_map[field_name] = row[index]
          Logger.info "- #{field_name} -> #{row[index]}"
        end
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
            
            field_value = @row_map[field_name]
            # Check for token pattern: {{some_value}}
            match = /\{\{(.*?)\}\}/.match(field_value)
            if match
              field_value = @field_expander.expand(match[1], model_key)
            end

            # Check for Boolean values
            if field_value
              downcased = field_value.downcase
              if downcased == 'y' || downcased == 'yes' || downcased == 'true'
                field_value = true
              elsif downcased == 'n' || downcased == 'no' || downcased == 'false'
                field_value = false
              end
            end

            # Use mapping if it exists
            model_fields[mapped_to_field_name || field_name] = field_value

          end
        end
        return model_fields
      end

      # TODO: Refactor this big ugly beast
      def add_associations(model, mapping)
        associations_mapping = mapping[:associations]
        if associations_mapping
          Logger.info "Adding associations to model"

          # Loop through any associations defined in the mapping for this model
          associations_mapping.each do |association_mapping|
            # Use the spreadsheet name unless 'map_to_class' is set
            if !association_mapping[:polymorphic]
              association_class_name = @name_class_map.resolve_mapped_from_original association_mapping[:name].classify
            else
              possible_class_names = association_mapping[:name]
              type = association_mapping[:polymorphic][:type]
              association_class_name = DriveTime::class_name_from_title @row_map[type]
            end
            # Get class reference using class name
            begin
              clazz = association_class_name.constantize
            rescue
              raise NoClassWithTitleError, "Association defined in worksheet doesn't exist as class #{association_class_name}"
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
          association_class = @name_class_map.resolve_original_from_mapped(association_class_name).underscore
          if !association_mapping[:polymorphic]
            association_id = @row_map[association_class]
          else
            association_id = @row_map[association_mapping[:polymorphic][:association]]
          end
          raise MissingAssociationError, "No field #{association_class_name.underscore} to satisfy association" if !association_id
          unless association_mapping[:inverse]
            associated_models << model_for_id(association_id, clazz)
          end
        end
        return associated_models
      end

      def set_associations_on_model(model, associated_models, association_mapping, association_class_name)
        # We now have one or more associated_models to set as associations on our model
        associated_models.each do |associated_model|
          Logger.info "Model #{associated_model}"
          unless association_mapping[:inverse] == true
            association_name = association_class_name.underscore
            if association_mapping[:singular] == true
              Logger.info "- Adding association #{associated_model} to #{model}::#{association_name}"
              # Set the association
              model.send("#{association_name}=", associated_model)
            else
              association_name = association_name.pluralize
              model_associations = model.send(association_name)
              Logger.info "- Adding association #{associated_model} to #{model}::#{association_name}"
              # Push the association
              model_associations << associated_model
            end
          else # The relationship is actually inverted, so save the model as an association on the associated_model
            model_name = model.class.name.underscore
            if association_mapping[:singular] == true
              Logger.info "- Adding association #{model} to #{associated_model}::#{association_name}"
              associated_model.send model_name, model
            else
              model_name = model_name.pluralize
              model_associations = associated_model.send model_name
              Logger.info "- Adding association #{model} to #{associated_model}::#{model_name}"
              model_associations << model
            end
          end
        end
      end

      def associated_models_from_builder(association_mapping, class_name)
        associated_models = []
        if association_mapping[:builder] == 'multi' # It's a multi value, find a matching cell and split its value by comma
          cell_value = @row_map[class_name.underscore.pluralize]
          raise MissingAssociationError "No field #{class_name.underscore.pluralize} to satisfy multi association" if !cell_value && association_mapping[:optional] != true;
          components = cell_value.split ','

          components.each do |component|
            associated_models << model_for_id(component, class_name)
          end

        elsif association_mapping[:builder] == 'use_fields' # Use column names as values if cell contains 'yes' or 'y'
          association_mapping[:field_names].each do |field_name|
            cell_value = @row_map[field_name]
            if DriveTime.is_affirmative? cell_value
              associated_models << model_for_id(field_name, class_name)
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
          if key_node[:builder] == 'join'
            key = JoinBuilder.new.build key_node[:from_fields], @row_map
          elsif key_node[:builder] == 'name'
            key = NameBuilder.new.build key_node[:from_fields], @row_map
          else
            raise "No builder for key on worksheet #{mapping[:title]}"
          end
        else # If it's a string, it refers to a spreadsheet column
          key_attribute = key_node
          # Is there a column
          key = @row_map[key_attribute]
          raise NoFieldNameError, "No column #{key_attribute} on worksheet #{mapping[:title]}" if !key
          DriveTime.underscore_from_text key
        end
      end
  end
end
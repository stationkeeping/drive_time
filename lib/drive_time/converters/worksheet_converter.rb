module DriveTime

  class WorksheetConverter

    class NoClassWithTitleError < StandardError; end
    class NoFieldNameError < StandardError; end
    class MissingAssociationError < StandardError; end

    def initialize(model_store, name_class_map)
      @name_class_map = name_class_map
      @model_store = model_store
    end

    def convert(worksheet)
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
        # Create a hash of field-names and row cell values
        row_map = HashWithIndifferentAccess.new
        Logger.info "Mapping fields to cells"
        row.dup.each_with_index do |cell, index|
          # Sanitise
          field_name = DriveTime.underscore_from_text fields[index]
          row_map[field_name] = row[index]
          Logger.info "- #{field_name} -> #{row[index]}"
        end

        # If a row has been marked as not complete, ignore it
        if row_map[:complete] == 'No'
          Logger.info 'Row marked as not complete. Ignoring'
          return
        end

        # Build hash ready to pass into model
        model_fields = row_fields_to_model_fields mapping, row_map
        Logger.info "Creating Model of class #{clazz.name.to_s} with Model Fields #{model_fields.to_s}"
        # Create new model
        model = clazz.new(model_fields, without_protection: true)
        # Add its associations
        add_associations model, mapping, row_map
        # Store the model using its ID
        model_key = get_id_for_model mapping, row_map
        @model_store.add_model model, model_key
      end

      # Run through the mapping's fields and convert them
      def row_fields_to_model_fields(mapping, row_map)
        model_fields = HashWithIndifferentAccess.new
        # Run through the mapping, pulling values from row_map as required
        mapping[:fields].each do |value|
          field_name = value[:name]
          unless field_name
            raise NoFieldNameError "Missing Field Name for field: #{value} in mapping: #{mapping}"
          end
          model_fields[field_name] = row_map[:field_name]
        end
        return model_fields
      end

      # TODO: Refactor this big ugly beast
      def add_associations(model, mapping, row_map)
        Logger.info "Adding associations to model"
        # Are there any assocations defined?
        if mapping[:associations]
          mapping[:associations].each do |value|
            # Use the spreadsheet name unless 'map_to_class' is set
            class_name = @name_class_map.resolve_mapped_from_original value[:name].classify
            # Get class reference using class name
            begin
              clazz = class_name.constantize
            rescue
              raise NoClassWithTitleError, "Association defined in worksheet #{mapping[:title]} doesn't exist as class #{class_name}"
            end

            # Assemble model instances that have already been created to satisfy associations 
            models = []
            # If a builder is defined, transform the cell contents
            if value[:builder]
              cell_value = cell_value_from_builder value, row_map, models, class_name
            else # It's a single text value, so convert it to an ID
              cell_value = row_map[@name_class_map.resolve_original_from_mapped(class_name).underscore]
              raise MissingAssociationError, "No field #{class_name.underscore} to satisfy association" if !cell_value

              unless value.has_key? 'inverse'
                models << get_model_for_id(cell_value, clazz)
              end
            end

            # We now have one or more models with which to associate our model
            models.each do |associated_model|
              Logger.info "Model #{associated_model}"
              unless value[:inverse] == true
                association_name = class_name.underscore
                if value[:singular] == true
                  Logger.info "- Adding association #{associated_model} to #{model}::#{association_name}"
                  # Set the association
                  model.send("#{association_name}=", associated_model)
                else
                  association_name = association_name.pluralize
                  associations = model.send(association_name)
                  Logger.info "- Adding association #{associated_model} to #{model}::#{association_name}"
                  # Push the association
                  associations << associated_model
                end
              else # The relationship is actually inverted, so save the model as an association on the associated_model
                model_name = model.class.name.underscore
                if value[:singular] == true
                  Logger.info "- Adding association #{model} to #{associated_model}::#{association_name}"
                  associated_model.send model_name, model
                else
                  model_name = model_name.pluralize
                  associations = associated_model.send model_name
                  Logger.info "- Adding association #{model} to #{associated_model}::#{model_name}"
                  associations << model
                end
              end
              # Save the model to the database
              persist_model model
            end
          end
        end
      end

      # Broken out to it can be stubbed
      def persist_model(model)
         model.save!
      end

      def cell_value_from_builder(value, row_map, models, class_name)
        if value[:builder] == 'multi' # It's a multi value, find a matching cell and split its value by comma

          cell_value = row_map[class_name.underscore.pluralize]
          raise MissingAssociationError "No field #{class_name.underscore.pluralize} to satisfy multi association" if !cell_value && value[:optional] != true;
          components = cell_value.split ','

          components.each do |component|

            models << get_model_for_id(DriveTime.underscore_from_text(component), class_name)
          end

        elsif value[:builder] == 'use_fields' # Use column names as values if cell contains 'yes' or 'y'
          value[:field_names].each do |field_name|
            cell_value = row_map[field_name]
            if DriveTime.is_affirmative? cell_value
              models << get_model_for_id(field_name, class_name)
            end
          end
        end
        return cell_value
      end

      def get_model_for_id(title, clazz)
        model_key = DriveTime.underscore_from_text title
        return @model_store.get_model clazz, model_key
      end

      def get_id_for_model(mapping, row_map)
        key_node = mapping[:key]
        if key_node.is_a? Hash
          if key_node[:builder] == 'join'
            key = JoinBuilder.new.build key_node[:from_fields], row_map
          elsif key_node[:builder] == 'name'
            key = NameBuilder.new.build key_node[:from_fields], row_map
          else
            raise "No builder for key on worksheet #{mapping[:title]}"
          end

        else # If it's a string, it refers to a spreadsheet column
          key_attribute = key_node
          # Is there a column
          begin
            key = row_map[key_attribute]
          rescue
            raise "No column #{key_attribute} on worksheet #{mapping[:title]}"
          end
        end
      end
  end
end
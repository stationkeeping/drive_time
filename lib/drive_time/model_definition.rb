module DriveTime

  class ModelDefinition

    attr_accessor :mapping
    attr_accessor :expander

    def initialize(definition, mapping)
      @definition = definition
      @mapping = mapping
      @key = build_key
      # Set the model key as an attribute on the model
      attributes[mapping.key_to] = @key if mapping.key_to
    end

    def is_complete?
      DriveTime.is_negative?(@definition[:complete])
    end

    def type
      @definition[:type].constantise
    end

    def has_value_for?(key)
      @definition.has_key?(key)
    end

    def value_for(key)
      key = DriveTime.underscore_from_text(key)
      if has_value_for?(key)
        @definition[key]
      else
        raise MissingFieldError, "No field for key: '#{key}' on model: '#{@key}' with attributes: '#{attributes}'"
      end
    end

    def key
      @key
    end

    # Run through the mapping's attributes and convert them
    def attributes
      @attributes ||= parse_attributes
    end

    def method_calls
      @method_calls ||= parse_method_calls
    end

    protected

    def parse_attributes
      @attributes = HashWithIndifferentAccess.new
      # Run through the mapping, pulling values from model_definition as required
      @mapping.attributes.each do |attribute_mapping|
        attribute_name = attribute_mapping[:name]
        mapped_to_attribute_name = attribute_mapping[:map_to]

        unless attribute_name
          raise NoFieldNameError "Missing Field: 'Name' 'for attribute: '#{value}'' in mapping: '#{mapping}'"
        end

        parse_markdown = DriveTime.is_affirmative?(attribute_mapping[:markdown])
        attribute_value = parse_attribute_value(attribute_name, parse_markdown)
        @attributes[mapped_to_attribute_name || attribute_name] = attribute_value
      end
      return @attributes
    end

    def parse_method_calls
      @method_calls = []
      # Run through the mapping, pulling values from model_definition as required
      @mapping.calls.each do |call_mapping|
        attribute_name = call_mapping[:name]
        methods = call_mapping[:methods]
        unless methods
          raise NoMethodError "Missing method 'Methods' for: '#{attribute_name}'' in mapping: '#{mapping}'"
        end
        # Handle strings like 'something.something_else' as well as [something, something_else]
        methods = methods.split('.') unless methods.kind_of?(Array)
        attribute_value = parse_attribute_value(attribute_name)
        # handle multi-values
        if call_mapping[:builder] == "multi"
          attribute_value = MultiBuilder.new.build(attribute_value)
        end
        @method_calls << {"methods" => methods, "value" => attribute_value}
      end
      return @method_calls
    end

    def parse_attribute_value(attribute_name, parse_markdown=false)
      attribute_value = value_for(attribute_name)
      if attribute_value
        attribute_value = check_for_token(attribute_value)
        attribute_value = DriveTime.check_string_for_boolean(attribute_value)
      end
      # Make sure any empty cells give us nil (rather than an empty string)
      attribute_value = nil if attribute_value.blank?

      attribute_value = Maruku.new(attribute_value.gsub(/\r/,"\n")) if parse_markdown && attribute_value.present?

      attribute_value
    end

    def check_for_token(value)
      # Check for token pattern: {{some_value}}
      token = /\{\{(.*?)\}\}/.match(value)
      if token
        expander.expand(token[1], key)
      else
        value
      end
    end

    def build_key
      key = mapping.key
      if key.is_a? Hash
        id_from_builder(key)
      else # If it's a string, it refers to an attribute
        key = value_for(key)
        raise NoFieldNameError, "No field: '#{key}' on source: '#{@mapping.title}'" if !key
        DriveTime.underscore_from_text(key)
      end
    end

    def id_from_builder(key)
      if key[:builder] == "join"
        JoinBuilder.new.build(key[:from_attributes], self)
      elsif key[:builder] == "name"
        NameBuilder.new.build(key[:from_attributes], self)
      else
        raise "No builder for key: '#{key}' on Source"
      end
    end

  end
end

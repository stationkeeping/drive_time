module DriveTime

	class BiDirectionalHash

		def initialize 
			@key_to_value = {}
			@value_to_key = {}
		end

		def insert(key, value)
			@key_to_value[key] = value;
			@value_to_key[value] = key;
		end

		def value_for_key(key)
			puts @key_to_value.inspect
			return @key_to_value[key]
		end

		def key_for_value(value)
			puts @value_to_key.inspect
			return @value_to_key[value]
		end

		def has_key_for_value(value)
			return !key_for_value(value).nil?
		end

		def has_value_for_key(key)
			return !value_for_key(key).nil?
		end

	end

end
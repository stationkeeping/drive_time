module DriveTime

  class TokenExpansionError < StandardError; end

  class FieldExpander

    def initialize()
      @expanders = {}
    end

    def register_expander(expander)
      @expanders[expander.key] = expander
    end

    def expand(token, filename)
      puts ">>>>>>>>> #{token} #{filename}"
      # Check for explicit filename defined within hard brackets [filename]
      match = /\[(.*?)\]/.match(token)
      filename = match[1] if match

      key = token.split("[").first
      key.slice!("expand_")

      puts ">>>>>>>>> #{token}"
      if @expanders[key].present?
        @expanders[key].expand(filename)
      else
        raise TokenExpansionError, "Don't have a registered expander for #{key} for file: #{filename}"
      end
    end

  end
end

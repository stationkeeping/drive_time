module DriveTime

  class TokenExpansionError < StandardError; end

  class FieldExpander

    def initialize()
      @providers = {}
    end

    def register_provider(provider)
      @providers[provider.key] = provider
    end

    def expand(token, filename)
      # Check for explicit filename defined within hard brackets [filename]
      match = /\[(.*?)\]/.match(token)
      filename = match[1] if match

      key = token.split("[").first
      key.slice!("expand_")

      puts "KEY #{key}"
      puts @providers.inspect

      if @providers[key].present?
        @providers[key].expand(filename)
      else
        raise TokenExpansionError, "Don't have a registered provider for #{key} for file: #{filename}"
      end
    end

  end
end
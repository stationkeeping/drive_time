module DriveTime

  class GoogleFileExpander

    attr_reader :key

    def initialize(loader)
      @loader = loader
      @key = 'file'
    end

    def expand(filename)
      file = @loader.load_file_direct("#{filename}.txt");
      if file.blank?
        raise TokenExpansionError, "Missing file named: #{filename}"
      end
      file.download_to_string()
    end

  end
end
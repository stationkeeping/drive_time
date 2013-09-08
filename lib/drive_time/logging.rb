require "log4r"

module Log4r
  class Logger
    def log_as_header(message)
      puts "\n"
      info "=============================================================================="
      info "#{message}"
      info '=============================================================================='
    end

    def log_as_sub_header(message)
      puts "\n" if self.level <= DEBUG
      debug "--------------------------------------------------------------------------------"
      debug "  #{message}"
      debug '--------------------------------------------------------------------------------'
    end
  end
end

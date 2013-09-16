module DriveTime

  # Split a string on ',' into an array of values
  class MultiBuilder

    def build(value)
        value = value.gsub("\n", "").strip.split(",") if value.present?
        value || []
    end

  end
end

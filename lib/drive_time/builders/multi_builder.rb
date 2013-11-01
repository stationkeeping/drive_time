module DriveTime

  # Split a string on ',' into an array of values
  class MultiBuilder

    def build(value)
      if value.blank?
        []
      else
        value = value.gsub("\n", "").strip.split(",")
      end
    end

  end
end

module DriveTime

  # Split a string on ',' into an array of values
  class MultiBuilder

   def build(value)
    if value.present?
      value = value.gsub("\n", "").strip.split(',')
    else
      []
    end
   end

  end
end
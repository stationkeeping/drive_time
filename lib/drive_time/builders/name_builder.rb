module DriveTime

  # Take a series of name fields. Look up their values and assemble them into a single id
  class NameBuilder < JoinBuilder
      
    protected

      def process_value(value)
        # Add a period to initials
        if value.length == 1
          return "#{value}."
        end
        return value
      end

  end

end
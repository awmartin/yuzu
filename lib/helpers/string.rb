
unless String.method_defined?(:titlecase)

  class String
    def titlecase
      self.downcase.spacify.split(" ").collect {|str| str.capitalize}.join(" ")
    end

    def titleize
      titlecase
    end

    def spacify
      self.gsub("-", " ").gsub("_", " ")
    end

    def dasherize
      self.gsub(" ", "-").gsub("_", "-")
    end

    def underline
      self.gsub(/\W/, "_")
    end

    def includes_one_of?(arr)
      tr = false
      arr.each do |el|
        tr ||= self.include?(el)
      end
      tr
    end

    def to_bool
      if self == "true"
        return true
      elsif self == "false"
        return false
      else
        raise ArgumentError, "String must be true or false to convert to TrueClass or FalseClass."
      end
    end
  end

end


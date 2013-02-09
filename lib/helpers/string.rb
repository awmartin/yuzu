
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

    def includes_one_of?(arr)
      tr = false
      arr.each do |el|
        tr ||= self.include?(el)
      end
      tr
    end
  end

end


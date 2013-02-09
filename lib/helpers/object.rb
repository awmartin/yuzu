unless Object.method_defined?(:blank?)

  class Object
    def blank?
      case
      when self.nil?
        true
      when is_a?(String)
        self.empty?
      when is_a?(Array)
        self.empty?
      else
        false
      end
    end
  end

end


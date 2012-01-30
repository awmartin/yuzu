module Wren
  module Helpers
    def change_extension file_path, new_extension
      file_path.to_s.gsub(File.extname(file_path), new_extension)
    end
  end
end

unless Object.method_defined?(:blank?)
  class Object
    def blank?
      return true if self.nil?
      if is_a?(String) or is_a?(Array)
        return true if self.empty?
      end
    end
  end
end

unless String.method_defined?(:titlecase)
  class String
    def includes_one_of? arr
      arr.collect {|str| self.include?(str)}.include?(true)
    end

    def titlecase
      self.downcase.split(" ").collect {|str| str.capitalize}.join(" ")
    end
    
    def titleize
      titlecase
    end
    
    def dasherize
      self.gsub(" ", "-").gsub("_", "-")
    end
  end
end

# Handles file path joins. Eliminates "." from the first arg, for consistency of Dir[...] results.
def file_join(*paths)
  if paths.first == "."
    File.join(paths[1, paths.length])
  else
    File.join(paths)
  end
end

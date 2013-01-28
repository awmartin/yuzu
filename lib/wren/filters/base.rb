
# Behaviors to support

# 1. Erase the directive or replace with new contents
# 2. Return the contents of the directive, if any
# 3. Defer to another method of finding the contents, if needed (e.g. from the filename)


module Wren
  module Filters
    class Base
      def init
      end
      
      def directive_name
        "DIRECTIVE"
      end

      def name
        :directive
      end

      def value(match)
        nil
      end

      def replacement_contents
        ""
      end

      def alternative_value(file_cache)
        nil
      end

      def regex
        return /#{directive_name}\([\w\s\.\,\'\"\/\-]*)/
      end

      def process(processed_contents)
        contents = processed_contents.match(regex)
        @value = value(m[0])
        return contents
      end

  #categories = []
  #tr = str.gsub(/CATEGORIES\([\w\s\.\,\'\"\/\-]*\)/) do |s|
  #  categories = s.gsub("CATEGORIES(","").gsub(")","").split(",")
  #  categories = categories.collect {|str| str.strip.downcase}
  #  ""
  #end
  
  #if categories.blank?
  #  categories = ["uncategorized"] # TODO: config var for default category
  #end

    end
  end
end


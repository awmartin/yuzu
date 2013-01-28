module Wren::Filers
  class CategoriesFilter < Base
    def init
    end

    def name
      :categories
    end

    def directive
      "CATEGORIES"
    end

    def value(match)
      list = match.split(",")
      return list.collect {|cat| cat.strip}
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

    def alternative_value(file_cache)
      nil
    end
  end
end

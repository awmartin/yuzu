require 'helpers/url'
require 'helpers/path'

module Wren::Filters
  class CategoriesFilter < Filter
    def initialize
      @name = :categories
      @directive = "CATEGORIES"
    end

    def default(website_file)
      [Category.new("uncategorized", website_file)]
    end

    def get_value(website_file)
      m = match(website_file.raw_contents)
      return default(website_file) if m.nil?

      category_list = m.split(",")
      category_list.collect! {|cat| cat.strip.downcase}
      category_list.reject! {|cat| cat.empty?}
      category_list.collect {|cat| Category.new(cat, website_file)}
    end
  end
  Filter.register(:categories => CategoriesFilter)


  class Category
    attr_reader :name

    def initialize(name, website_file)
      @name = name.dasherize.downcase
      @website_file = website_file
    end

    def link
      Html::Link.new(:href => url) << @name.titlecase
    end

    def url
      @website_file.blog_folder.link_url + "/" + @name
    end

    def <=>(other)
      @name <=> other.name
    end
  end
end


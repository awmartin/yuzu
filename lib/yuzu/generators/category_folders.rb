require 'generators/base'
require 'generators/index'
require 'helpers/path'

module Yuzu::Generators
  class CategoryFoldersGenerator < Generator
    include Helpers

    def initialize
      @name = :category_folders
      @directive = "CATEGORYFOLDERS"
    end

    def should_generate?(website_folder)
      website_folder.is_blog?
    end

    def visitor_filter
      proc do |c| 
        if c.file?
          @all_categories = c.all_categories
        end
        c.folder?
      end
    end

    def generate!(website_folder)
      @all_categories.each do |category|
        generate_folder_for_category!(category, website_folder.blog_folder)
      end
    end

    def generate_folder_for_category!(category, blog_folder)
      blog_folder.append_child(folder_for_category(category, blog_folder))
    end

    def folder_for_category(category, blog_folder)
      category_folder = GeneratedFolder.new(category.path, blog_folder)
      index_child = index_for_category(category, category_folder, blog_folder)
      category_folder.append_child(index_child)
      category_folder
    end

    def index_for_category(category, parent_folder, blog_folder)
      GeneratedIndex.new(
        parent_folder,
        Yuzu::Generators.category_index_template(blog_folder.path.relative, category.name)
      )
    end

  end
  Generator.register(:category_folders => CategoryFoldersGenerator)


  class GeneratedFolder < WebsiteFolder
    include Helpers

    def initialize(path, parent, children=[])
      raise ArgumentError, "Not a Path object." if not path.is_a?(Path)
      @path = path
      raise "@path is nil for #{self}" if @path.nil?

      @parent = parent
      @children = children

      @kind = :folder
    end

    def to_s
      "GeneratedFolder(#{@path})"
    end

    def children
      @children.nil? ? [] : @children
    end

    def files
      @children.select {|c| c.file?}
    end

    def folders
      @children.select {|c| c.folder?}
    end

    def all_files
      files
    end
  end

end


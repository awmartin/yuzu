require 'helpers/import'

import 'yuzu/generators/base'
import 'yuzu/generators/index'

module Yuzu::Generators
  # The CategoryFoldersGenerator produces a folder and index file for every category encountered in
  # the blog. When the author uses a CATEGORIES() directive, e.g. CATEGORIES(process), the Generator
  # will produce a process/index.md file in the blog folder (e.g. blog/process/index.md), which will
  # be paginated, etc.
  class CategoryFoldersGenerator < Generator

    def initialize
      @name = :category_folders
      @directive = "CATEGORYFOLDERS"
    end

    def should_generate?(website_folder)
      website_folder.is_blog?
    end

    # Returns a filter to traverse folders and to gather the Categories to generate folders for.
    def visitor_filter
      proc do |c| 
        if c.file? and @all_categories.nil?
          # HACK Find a better way of gathering the categories outside of this stateful update in
          # the visitor's traversal.
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

    # Given a single category, this produces the files and folders needed to write the new category
    # folder and index. It stashes the new parent folder in the children of the blog.
    #
    # @param [Category] category An instance of Category for which a folder will be generated.
    # @param [WebsiteFolder] blog_folder The blog folder.
    # @return nothing
    def generate_folder_for_category!(category, blog_folder)
      blog_folder.append_child(folder_for_category(category, blog_folder))
    end

    # Return a WebsiteFolder that will represent the given Category.
    #
    # @param [Category] category An instance of Category for which a folder will be generated.
    # @param [WebsiteFolder] blog_folder The blog folder.
    # @return nothing
    def folder_for_category(category, blog_folder)
      category_folder = GeneratedFolder.new(category.path, blog_folder)
      index_child = index_for_category(category, category_folder, blog_folder)
      category_folder.append_child(index_child)
      category_folder
    end

    # Produces a GeneratedIndex for the given category.
    #
    # @param [Category] category An instance of Category for which a folder will be generated.
    # @param [WebsiteFolder] parent_folder The folder with the name of the Category that will
    #   contain this index file.
    # @param [WebsiteFolder] blog_folder The blog folder.
    # @return [GeneratedIndex] Represents the index.html file.
    def index_for_category(category, parent_folder, blog_folder)
      GeneratedIndex.new(
        parent_folder,
        Yuzu::Generators.category_index_template(blog_folder.path.relative, category.name)
      )
    end

  end
  Generator.register(:category_folders => CategoryFoldersGenerator)


  class GeneratedFolder < WebsiteFolder

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


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
      website_folder.is_blog? or website_folder.root?
    end

    # Returns a filter to traverse folders and to gather the Categories to generate folders for.
    def visitor_filter
      proc do |c| 
        if c.file? and @all_categories.nil?
          # HACK Find a better way of gathering the categories outside of this stateful update in
          # the visitor's traversal.
          @all_categories = c.all_categories
        end

        if c.file? and @blog_categories.nil?
          @blog_categories = c.blog_categories
        end

        c.folder?
      end
    end

    # Generates the folders and indices for each category in the given context.
    #
    # @param [WebsiteFolder] website_folder The parent website folder in which we're going to
    #   generate category folders.
    def generate!(website_folder)
      if website_folder.is_blog? and not @blog_categories.nil?
        @blog_categories.each do |category|
          generate_folder_for_category!(category, website_folder.blog_folder)
        end
      elsif website_folder.root? and not @all_categories.nil?
        @all_categories.each do |category|
          generate_folder_for_category!(category, website_folder.root)
        end
      end
    end

    # Given a single category, this produces the files and folders needed to write the new category
    # folder and index. It stashes the new parent folder in the children of the blog.
    #
    # @param [Category] category An instance of Category for which a folder will be generated.
    # @param [WebsiteFolder] parent_folder The containing folder.
    # @return nothing
    def generate_folder_for_category!(category, parent_folder)
      category_folder_name = category.name
      parent_folder_child_folder_names = parent_folder.children.select {|c| c.folder?}.collect {|f| f.path.name}

      if not parent_folder_child_folder_names.include?(category_folder_name)
        parent_folder.append_child(folder_for_category(category, parent_folder))
      end
    end

    # Return a WebsiteFolder that will represent the given Category.
    #
    # @param [Category] category An instance of Category for which a folder will be generated.
    # @param [WebsiteFolder] parent_folder The containing folder.
    # @return nothing
    def folder_for_category(category, parent_folder)
      category_folder = GeneratedCategoryFolder.new(category, parent_folder)
      index_child = index_for_category(category, category_folder, parent_folder)
      category_folder.append_child(index_child)
      category_folder
    end

    # Produces a GeneratedIndexFile for the given category.
    #
    # @param [Category] category An instance of Category for which a folder will be generated.
    # @param [WebsiteFolder] parent_folder The folder with the name of the Category that will
    #   contain this index file.
    # @param [WebsiteFolder] parent_folder The containing folder for the category folder.
    # @return [GeneratedIndexFile] Represents the index.html file.
    def index_for_category(category, category_folder, parent_folder)
      GeneratedCategoryIndexFile.new(
        category_folder,
        category,
        Yuzu::Generators.category_index_template(parent_folder.path.relative, category.name)
      )
    end

  end
  Generator.register(:category_folders => CategoryFoldersGenerator)


  class GeneratedCategoryIndexFile < GeneratedIndexFile
    attr_reader :category

    def initialize(parent_folder, category, raw_contents=nil)
      @parent = parent_folder
      @category = category
      @raw_contents = raw_contents

      index_path = parent_folder.path + default_index_filename
      @path = index_path
      @path.make_file!
      raise "@path is nil for #{self}" if @path.nil?
      @page = 1

      @kind = :file
    end

    def to_s
      "GeneratedCategoryIndexFile(#{@path.relative})"
    end
  end


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


  class GeneratedCategoryFolder < GeneratedFolder
    attr_reader :category

    def initialize(category, parent_folder, children=[])
      @category = category
      @path = category.path
      raise "@path is nil for #{self}" if @path.nil?

      @parent = parent_folder
      @children = children

      @kind = :folder
    end
  end

end


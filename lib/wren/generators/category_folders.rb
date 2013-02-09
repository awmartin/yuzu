require 'generators/index'

module Wren::Generators
  class IndexGenerator < Generator

    def initialize
      @name = "category_folders"
      @directive = "CATEGORYFOLDERS"
    end

    def should_generate?(website_folder)
      website_folder.is_blog?
    end

    def visitor_filter
      proc {|c| c.folder?}
    end

    def generate!(website_folder)
      website_folder.all_categories.each do |cat|
        generate_index_at_path!(cat.link)
      end
    end

    def generate_index_at_path!(website_folder)
      new_index = GeneratedIndex.new(website_folder)
      website_folder.append_child(new_index)
    end
  end


  class GeneratedFolder < WebsiteFolder
    def to_s
      "GeneratedFolder(#{@path})"
    end

    def children
      files + folders
    end

    def files
      [GeneratedIndex.new(self)]
    end

    def folders
      []
    end

    def all_files
      files
    end
  end

end


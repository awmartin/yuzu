require 'helpers/import'

import 'yuzu/generators/base'

module Yuzu::Generators
  class IndexGenerator < Generator

    @@indexed_folders = []
    def self.get_indexed
      @@index_folders
    end

    def self.add_indexed_folder(folder)
      @@indexed_folders.push(folder)
    end

    def self.is_indexed?(folder)
      @@indexed_folders.include?(folder)
    end

    def initialize
      @name = "index"
      @directive = "INDEX"
    end

    def should_generate?(website_folder)
      not IndexGenerator.is_indexed?(website_folder) and \
        not website_folder.has_index?
    end

    def visitor_filter
      proc {|c| c.folder? and c.config.can_index_folder?(c.path)}
    end

    def generate!(website_folder)
      return if IndexGenerator.is_indexed?(website_folder)

      generate_index_at_path!(website_folder)
    end

    def generate_index_at_path!(website_folder)
      new_index = GeneratedIndexFile.new(website_folder)

      website_folder.append_child(new_index)
      IndexGenerator.add_indexed_folder(website_folder)
    end
  end


  class GeneratedIndexFile < WebsiteFile
    def initialize(parent_folder, raw_contents=nil)
      @raw_contents = raw_contents

      index_path = parent_folder.path + default_index_filename
      @path = index_path
      @path.make_file!
      raise "@path is nil for #{self}" if @path.nil?
      @parent = parent_folder
      @page = 1

      @kind = :file
    end

    def to_s
      "GeneratedIndexFile(#{@path.relative})"
    end

    def default_index_filename
      "index.md"
    end

    def get_raw_contents
      # Only becomes @raw_contents if it is still nil when raw_contents is first called.
      if @parent.is_blog?
        Yuzu::Generators.default_blog_index_template(@parent.path.relative)
      else
        Yuzu::Generators.default_index_template(@parent.path.relative)
      end
    end

    def created_at
      @created_at ||= Time.now
    end

    def modified_at
      @modified_at ||= Time.now
    end

    def load_file_info!
    end

    def generated?
      true
    end
  end
  Generator.register(:index => IndexGenerator)

  # TODO Put the auto-generated index contents in their own files.
  def default_index_template(relative_contents_path)
      "TEMPLATE(index.haml)

INSERTCATALOG(path:#{relative_contents_path}, page:1, per_page:10, per_col:1, template:_block.haml)"
  end
  module_function :default_index_template

  def default_blog_index_template(relative_contents_path)
      "TEMPLATE(blog.haml)

INSERTCATALOG(path:#{relative_contents_path}, page:1, per_page:10, per_col:1, template:_blog.haml)"
  end
  module_function :default_blog_index_template

  def category_index_template(relative_contents_path, category_name)
      "TEMPLATE(blog.haml)

INSERTCATALOG(path:#{relative_contents_path}, page:1, per_page:10, per_col:1, template:_blog.haml, category:#{category_name})"
  end
  module_function :category_index_template

end


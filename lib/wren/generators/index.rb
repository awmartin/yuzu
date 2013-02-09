

module Wren::Generators
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
      new_index = GeneratedIndex.new(website_folder)
      website_folder.append_child(new_index)
      IndexGenerator.add_indexed_folder(website_folder)
    end
  end


  class GeneratedIndex < WebsiteFile
    def initialize(parent_folder)
      index_path = parent_folder.path + default_index_filename

      @path = index_path
      @path.make_file!
      raise "@path is nil for #{self}" if @path.nil?
      @parent = parent_folder
      @page = 1

      @kind = :file
    end

    def to_s
      "GeneratedIndex(#{@path.relative})"
    end

    def file?
      true
    end

    def folder?
      false
    end

    def default_index_filename
      "index.md"
    end

    def get_raw_contents
      # TODO Put the auto-generated index contents in its own file.
      relative_path = @parent.path.relative
      "TEMPLATE(index.haml)

INSERTCATALOG(path:#{relative_path}, page:1, per_page:10, per_col:1, template:_block.haml)

<!--wren:nosearch-->"
    end

    def created_at
      load_file_info!
      @created_at
    end

    def modified_at
      load_file_info!
      @modified_at
    end

    def load_file_info!
      if @raw_contents.nil?
        f = File.open(@parent.path.absolute, "r")
        @modified_at = f.mtime
        @created_at = f.ctime
        f.close

        #f = File.open(index_template_path, "r")
        #@raw_contents = f.read
        #f.close
      end
    end

    def generated?
      true
    end
  end
  Generator.register(:index => IndexGenerator)

end


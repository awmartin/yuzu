require 'core/website_file'

module Wren::Core
  class PaginatedWebsiteFile < WebsiteFile
    attr_reader :original_file

    # Initialize a new generated file from an existing WebsiteFile
    # 
    # @param [WebsiteFile] original_file The root file representing page 1.
    # @param [String] new_raw_contents The new contents with the INSERTCATALOG directives updated to
    #   include the page:N argument.
    # @param [Fixnum] page The page that this generated file represents.
    def initialize(original_file, new_raw_contents, page)
      @raw_contents = new_raw_contents
      @page = page

      @path = Wren::Core.get_paginated_path(original_file.path, page)
      raise "@path is nil in #{self}" if @path.nil?

      @original_file = original_file
      @parent = original_file.parent
      @kind = :file
    end

    def to_s
      "PaginatedWebsiteFile(#{@path.relative})"
    end

    def get_raw_contents
      @raw_contents
    end

    def modified_at
      @original_file.modified_at
    end

    def created_at
      @original_file.created_at
    end

    def load_file_info!
      # No need to do anything here. All dependent methods are overridden.
    end

    def generated?
      true
    end

    def paginated?
      true
    end
  end

  # Calculate the page of this file, assuming it's a file produced from pagination.
  #
  # @param [Path] original_path The path of the original seed file being paginated.
  # @param [Fixnum] page The page of the new file.
  # @return [Path] The new path in the format path/to/file_N.ext where N is the page number.
  def get_paginated_path(original_path, page)
    new_path = original_path.dup
    new_path.make_file!
    tr = new_path.add_suffix(page)
    raise "New path is nil!" if tr.nil?
    tr.make_file!
    tr
  end
  module_function :get_paginated_path

end

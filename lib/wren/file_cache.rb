require 'maruku'
require 'haml'
require 'RedCloth'

require 'renderers/keyword_handlers'
require 'renderers/catalogs'
require 'renderers/breadcrumb'
require 'renderers/page_links'
require 'content_handlers'

require 'layout_handler'

class FileCache
  attr_accessor :site_cache, :config, :relative_path
  attr_writer :process_contents

  def initialize raw_path, config, page=1
    @raw_path = raw_path # Also the original path of page 1 if this is page n
    @config = config
    @page = page
  end
  
  def file_type
    if directory?
      if not index_exists?
        @file_type = :haml
      else
        @file_type = false
      end
    elsif @file_type.nil?
      if extension.includes_one_of? @config.image_extensions
        @file_type = :image
      elsif extension.includes_one_of? @config.asset_extensions
        @file_type = :asset
      elsif extension.includes_one_of? @config.resource_extensions
        @file_type = :resource
      elsif extension.includes_one_of? ["txt", "pde", "rb"]
        @file_type = :plaintext
      elsif extension.include? 'text'
        @file_type = :textile
      elsif extension.include? 'html'
        @file_type = :html
      elsif extension.include? 'haml'
        @file_type = :haml
      elsif extension.includes_one_of? ["markdown", "md", "mdown"]
        @file_type = :markdown
      else
        @file_type = :unknown
      end
    end
    @file_type
  end

  def default_index_contents
    # TODO: Change the first 0 to PAGINATE
    "INSERTCATALOG(#{@raw_path},0,10,3,_block.haml)
TEMPLATE(_index.haml)"
  end

  # Load the contents on demand.
  def raw_contents
    if @raw_contents.nil?
      if File.exists? @raw_path

        if file?
          if processable?
            # Open the file and grab its contents
            f = File.open @raw_path, "r"
            @raw_contents = f.readlines.join
            @modified_date = f.mtime
            @created_date = f.ctime
            f.close
          else
            # Either blacklisted or a binary file. Open later.
            @raw_contents = nil
          end
        else
          if index_exists?
            # Return the contents of the actual index, since an index file exists.
            @raw_contents = @site_cache.cache[index_path].raw_contents
          else
            # Just make up some contents. TODO: Make defaults configurable.
            @raw_contents = default_index_contents
          end
        end

      else # file doesn't exist.
        @raw_contents = ""
      end
    end

    @raw_contents
  end
  
  def process_contents
    if @process_contents.nil?
      @process_contents = raw_contents.dup
    end
    @process_contents
  end

  def rendered_path
    if index? and directory?
      if paginate? and @page > 1
        # Don't paginate generated indices just yet.
        # If auto-generated indices were paginated, this would add a digit
        # to the end of the filename.
        return File.join @raw_path, "index.html" 
      else
        return File.join @raw_path, "index.html"
      end
    end
    
    if not processable?
      return paginated_path
    else
      if file?
        return paginated_path.gsub(extension, output_extension)
      else
        return paginated_path
      end
    end
  end

  def processable?
    extension.includes_one_of?(@config.processable_extensions) or (index? and not (directory? and index_exists?))
  end

  def blacklisted?
    extension.includes_one_of? @config.extension_blacklist or relative_path.includes_one_of? @config.folder_blacklist
  end

  def index_exists?
    if file?
      @index_exists = false
      @index_path = ""
    elsif @index_exists.nil? or @index_path.nil?
      @index_exists, @index_path = get_index_info
    end
    @index_exists
  end

  def index_path
    if file?
      @index_exists = false
      @index_path = ""
    elsif @index_exists.nil? or @index_path.nil?
      @index_exists, @index_path = get_index_info
    end
    @index_path
  end

  def get_index_info
    if file?
      @index_exists = false
      @index_path = ""
    elsif @index_exists.nil?
      
      @config.indices.each do |index|
        path = File.join @raw_path, index

        if File.exists? path
          @index_exists = true
          @index_path = path
          break
        else
          @index_exists = false
          @index_path = ""
        end

      end
    end
    return @index_exists, @index_path
  end

  def children
    if file?
      @children = []
    else
      if @children.nil?
        # traverse
        @children = []
        search_path = File.join @raw_path, "**/*"
        @children = Dir[search_path]
      end
    end
    @children
  end
  
  def processable_children
    children.select { |path| @site_cache.cache[path].processable? }
  end

  def catalog_children
    if @catalog_children.nil?
      child_file_caches = children.collect {|f| @site_cache.cache[f]}
      unsorted = child_file_caches.select {|f| f.file? and f.processable? and !f.index?}
      @catalog_children = unsorted.sort {|a, b| b.raw_post_date <=> a.raw_post_date}
    end
    @catalog_children
  end
  
  def absolute_path
    File.join Dir.pwd, relative_path
  end

  def link_url
    File.join @config.link_root, rendered_path
  end
  
  def directory?
    File.directory? @raw_path
  end
  
  def file?
    not directory?
  end
  
  def basename
    File.basename @raw_path
  end

  def relative_path
    paginated_path
  end

  # Takes the raw path and tacks _3.haml or similar to the end of it.
  def paginated_path
    if @paginated_path.nil?
      if file? and paginate?
        if @page > 1
          # Paginated file path. Instead of file.haml, you get file_3.haml for page 3.
          page_name = basename.gsub(extension, "") + "_#{@page}#{extension}"
          @paginated_path = @raw_path.gsub(basename, page_name)
        else
          @paginated_path = @raw_path
        end
      else # directory
        @paginated_path = @raw_path
      end
    end
    @paginated_path
  end

  def path_to
    if file?
      relative_path.gsub(basename, "")
    else
      relative_path
    end
  end
  
  def index?
    basename.include?("index.") or (directory? and not @raw_path.includes_one_of?(@config.no_index_folders))
  end
  
  def extension
    File.extname @raw_path
  end
  
  def image?
    file_type == :image
  end

  def asset?
    file_type == :asset
  end

  def resource?
    file_type == :resource
  end

  def template
    preprocess!
    @template
  end

  def images
    preprocess!
    @images
  end

  def output_extension
    preprocess!
    @output_extension
  end

  def html_title
    preprocess!
    @html_title
  end

  def post_title
    preprocess!
    @post_title
  end

  # Formatted
  def post_date
    preprocess!
    @post_date
  end

  # Unformatted, e.g. 2011-08-01
  def raw_post_date
    preprocess!
    @raw_post_date
  end

  def categories
    preprocess!
    @categories
  end

  def gallery
    preprocess!
    @gallery
  end

  def show_gallery
    preprocess!
    @show_gallery
  end

  def sidebar_contents
    preprocess!
    @sidebar_contents
  end

  def breadcrumb
    preprocess!
    @breadcrumb
  end

  def description
    preprocess!
    @description
  end

  # ---------------------
  # Used for pagination. Only one catalog per file is allowed to paginate.
  # @fc_start will be -1 for pagination.
  # @fc_count will be 0 for "show all," which is contrary to pagination.
  def get_first_catalog_info!
    @fc_folder, @fc_start, @fc_count, @fc_blocks, @fc_block_template = extract_first_catalog raw_contents
  end

  def num_pages
    if paginate? or @num_pages.nil?
      num_items = @site_cache.cache[@fc_folder].catalog_children.length
      @num_pages = (num_items.to_f / @fc_count.to_f).ceil # round up
    else
      @num_pages = 1
    end
    @num_pages
  end

  def items_per_page
    if paginate?
      @fc_count
    else
      0
    end
  end

  def paginate?
    if processable?
      if @paginate.nil?
        if @fc_start.nil?
          get_first_catalog_info!
          if @fc_start == -1 # Magic number!
            @paginate = true
          else
            @paginate = false
          end
        end
      end
    else
      @paginate = false
    end
    @paginate
  end

  def page
    @page
  end

  def page_links
    if @page_links.nil?
      if paginate?
        @page_links = render_page_links num_pages, File.join(@config.link_root, @raw_path), @page
      else
        @page_links = ""
      end
    end
    @page_links
  end

  # ----------------------

  def preprocess!
    return if @preprocessed
    
    # ------ Pagination ------
    offset = (@page - 1) * items_per_page
    # Only the first INSERTCATALOG is paginated, since the items_per_page only comes
    # from the first one found.
    @process_contents = process_contents.gsub("PAGINATE", offset.to_s)

    # Insert contents before extracting the categories, template, and images...
    # This inserts the raw contents of a file. The format must be the same as the parent.
    @process_contents = insert_contents process_contents
    
    # ----------------- Extractions --------------------
    @categories, @process_contents = extract_categories process_contents
    @template, @process_contents = extract_template process_contents
    @images, @process_contents = extract_images process_contents, @config.link_root
    @show_gallery, @process_contents = show_gallery? process_contents
    
    @post_title, @process_contents = extract_title process_contents
    if @post_title.blank?
      @post_title = extract_title_from_filename @raw_path
    end
    
    @raw_post_date, @process_contents = extract_date process_contents
    if @raw_post_date.blank?
      @raw_post_date = extract_date_from_filename @raw_path
    end
    @post_date = format_date @raw_post_date
    
    @output_extension, @process_contents = extract_extension process_contents
    @description, @process_contents = extract_description_meta process_contents
    
    # -----------------
    
    # Catalogs are paginated, PAGINATE is replaced above.
    # Catalogs must be inserted before SIDEBARCONTENTS is interpreted, in case
    # there is a catalog in there. Not sure if it really works, because of HAML
    # indentation weirdness...
    @process_contents = insert_catalogs @site_cache, process_contents, @page
    
    @sidebar_contents, @process_contents = extract_sidebar_contents process_contents
    @sidebar_contents = render @sidebar_contents
    
    # Replace LINKROOT and CURRENTPATH once all the other content has been inserted...
    # TODO: Make sure CURRENTPATH is working properly.
    @process_contents = insert_currentpath process_contents, File.join(@config.link_root, path_to)
    @process_contents = insert_linkroot process_contents, @config.link_root
    
    # Generated content ...
    @breadcrumb = render_breadcrumb self, @categories
    @html_title = build_title @raw_path, @config.site_name, @post_title
    @gallery = render_gallery @images, @config
    
    @preprocessed = true
  end

  def rendered_contents
    if @rendered_contents.nil?
      @rendered_contents = render process_contents
    end
    @rendered_contents
  end

  def render str
    if file_type == :asset or file_type == :image
      # Images and other binary files... Do nothing.
      return nil
    elsif file_type == :plaintext or file_type == :html
      return str
    elsif file_type == :textile
      return RedCloth.new(str).to_html
    elsif file_type == :haml
      return Haml::Engine.new(str, {:format => :html5}).render #(Object.new, {})
    elsif file_type == :markdown
      return Maruku.new(str).to_html
    else
      return str
    end
  end

  def first_paragraph
    if @first_paragraph.nil? or @raw_first_paragraph.nil?
      @raw_first_paragraph = ""
      @first_paragraph = ""
          
      if processable?
        html_pattern = /<p\b[^>]*>((.|\n)*?)<\/p>/
        lines = rendered_contents.split("\n")
        lines.each do |line|
          m = line.match(html_pattern)
          if not m.nil?
            @raw_first_paragraph = m[0]
            @first_paragraph = m[1]
            break
          else
            @raw_first_paragraph = ""
            @first_paragraph = ""
          end
        end
      else
        @raw_first_paragraph = ""
        @first_paragraph = ""
      end
    end
    return @raw_first_paragraph, @first_paragraph
  end

  def first_image
    preprocess!
    if not @images.nil?
      if @images.length > 0
        @images.first
      else
        ""
      end
    else
      ""
    end
  end

  def first_image_thumbnails
    if first_image.blank?
      {
        :image_path => "",
        :image_path_small => "",
        :image_path_medium => "",
        :image_path_large => ""
      }
    else
      image_ext = File.extname(first_image)
      {
        :image_path => first_image,
        :image_path_small => first_image.gsub(image_ext, "-small#{image_ext}"),
        :image_path_medium => first_image.gsub(image_ext, "-medium#{image_ext}"),
        :image_path_large => first_image.gsub(image_ext, "-large#{image_ext}")
      }
    end
  end

  # Used for blocks in catalogs
  def attributes
    preprocess!
    
    if @attibutes.nil?
      raw_para, first_para = first_paragraph
      
      @attributes = ({
        :post_title => post_title,
        :post_date => post_date,
        :categories => categories,
        :html_title => html_title,
        :template => template,
        :show_gallery => show_gallery,
        :sidebar_contents => sidebar_contents,
        :images => images,
        :raw_path => @raw_path, # not paginated, always the first page "index.haml"
        :relative_path => relative_path, # paginated, like "index_2.haml"
        :output_extension => output_extension,
        :link_url => link_url,
        :raw_first_paragraph => raw_para,
        :first_paragraph => first_para,
        :gallery => gallery,
        :breadcrumb => breadcrumb,
        :link_root => @config.link_root,
        :domain => @config.domain,
        :page_links => page_links,
        :description => description.blank? ? first_para : description
      }.update(@config.config_dict)).update(first_image_thumbnails)
    end
    @attributes
  end

  # Handle the layout. Calls 'rendered_contents' and triggers the update.
  def html_contents
    LayoutHandler.new(self).wrap_with_layout
  end

  def contents
    if @contents.nil?
      if processable?
        @contents = html_contents
      else
        @contents = nil
      end
    end
    @contents
  end
  
end

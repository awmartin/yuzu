require 'renderers/all'
require 'renderers/keyword_handlers'
require 'renderers/catalogs'
require 'renderers/breadcrumb'
require 'renderers/page_links'

require 'content_handlers'
require 'layout_handler'
require 'helpers'

# Primary abstraction for a cached and renderable file. This is a location
# in the folder tree and has all of the logic required to render the file
# into HTML or other format.
class FileCache
  attr_accessor :site_cache, :config, :relative_path, :javascript_paths
  attr_writer :process_contents, :raw_contents
  attr_reader :page, :raw_path
  
  # Define some default accessors.
  @@preprocess_accessors = [:template, :images, 
    :html_title, :post_title, :post_date, :raw_post_date, :categories, 
    :gallery, :sidebar_contents, :breadcrumb, :description,
    :render_slideshow]
  
  @@preprocess_accessors.each do |method_name|
    define_method(method_name) do
      self.preprocess!
      return self.instance_variable_get("@#{method_name}".to_sym)
    end
  end
  
  def initialize(raw_path, config, page=1)
    @raw_path = raw_path # Also the original path of page 1 if this is page n
    @config = config
    @page = page
    @javascript_paths = []
  end
  
  # Without the link root, including the full path
  # e.g. js/slideshow.js
  def add_javascript_path path
    @javascript_paths += [file_join(@config.link_root, path)]
  end
  
  # Returns the file type of the target file. It is a symbol of type: :haml, :markdown, :plaintext,
  # etc.
  def file_type
    if directory?
      if not index_exists?
        @file_type = :haml
      else
        @file_type = false
      end
    elsif @file_type.nil?
      @file_type = get_file_type(extension, @config)
    end
    @file_type
  end

  def filename
    File.basename(@raw_path)
  end

  def default_index_contents
    # TODO: Change the first 0 to PAGINATE
    "INSERTCATALOG(#{@raw_path},0,10,3,_block.haml)
TEMPLATE(index.haml)
<!--wren:nosearch-->"
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
          elsif is_folder_index?
            # Just make up some contents. TODO: Make defaults configurable.
            @raw_contents = default_index_contents
          else
            @raw_contents = false
          end

        end

        # Replace CURRENTPATH
        @raw_contents.gsub!("CURRENTPATH", current_path)

      else 
        # file doesn't exist.
        @raw_contents = ""
      end
    end

    return @raw_contents
  end

  def current_path
    return file_join(@config.link_root, File.dirname(@raw_path))
  end
  
  def process_contents
    @process_contents ||= raw_contents.dup
  end

  def rendered_path
    if index? and directory?
      if paginate? and @page > 1
        # Don't paginate generated indices by default just yet.
        # If auto-generated indices were paginated, this would add a digit
        # to the end of the filename.
        return file_join @raw_path, "index.html" 
      else
        return file_join @raw_path, "index.html"
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
    if directory?
      return false
    else
      return extension.includes_one_of?(@config.processable_extensions)
    end
  end

  def blacklisted?
    extension.includes_one_of? @config.extension_blacklist or \
      relative_path.includes_one_of? @config.folder_blacklist
  end

  def index_exists?
    get_index_info!
    return @index_exists
  end

  def index_path
    get_index_info!
    return @index_path
  end

  def get_index_info!
    if file?
      @index_exists = false
      @index_path = ""
    elsif @index_exists.nil? or @index_path.nil?
      @index_exists = false
      @index_path = ""
      
      @config.possible_indices.each do |index|
        path = file_join @raw_path, index
        
        if File.exists? path
          @index_exists = true
          @index_path = path
        end
        
      end
    end
  end
  
  # Contains all the children of this folder.
  def children(deep=true)
    if file?
      @children = []
    else
      if @children.nil?
        # traverse
        @children = []
        if deep
          search_path = file_join(@raw_path, "**/*")
        else
          search_path = file_join(@raw_path, "*")
        end
        @children = Dir[search_path]
      end
    end
    @children
  end
  
  # Returns a list of child paths that contain processable, renderable files.
  def processable_children(deep=true)
    @processable_children ||= children(deep).reject { |path| 
          @site_cache.cache[path].nil?
        }.select { |path| 
          @site_cache.cache[path].processable? 
        }
  end
  
  def formatted_categories
    categories.collect {|cat| cat.to_s.downcase.dasherize}
  end
  
  def filtered_children(category_filter=nil, sort_by=:date_reversed, deep=true)
    sorted = catalog_children(nil, sort_by, deep)
    if category_filter.nil?
      filtered = sorted
    else
      formatted_filter = category_filter.to_s.downcase.dasherize
      filtered = sorted.select { |child| child.formatted_categories.include?(formatted_filter) }
    end
    return filtered
  end
  
  def catalog_children(category_filter=nil, sort_by=:date_reversed, deep=true)
    # This shouldn't really be cached because we may be rendering this multiple
    # times.
    #if @catalog_children.nil?
      child_file_caches = processable_children(deep).collect {|f| @site_cache.cache[f]}

      unsorted = child_file_caches.select {|f| f.file? and !f.index?}
      
      # Sort by date by default...
      if sort_by == :date_reversed
        @catalog_children = unsorted.sort {|a, b| b.raw_post_date <=> a.raw_post_date}
      elsif sort_by == :date
        @catalog_children = unsorted.sort {|a, b| a.raw_post_date <=> b.raw_post_date}
      elsif sort_by == :title
        @catalog_children = unsorted.sort {|a, b| a.post_title <=> b.post_title}
      elsif sort_by == :filename
        @catalog_children = unsorted.sort {|a, b| a.filename <=> b.filename}
      else
        @catalog_children = unsorted.sort {|a, b| b.raw_post_date <=> a.raw_post_date}
      end
    #end
    @catalog_children
  end
  
  def absolute_path
    file_join(Dir.pwd, relative_path)
  end

  def link_url
    file_join(@config.link_root, rendered_path)
  end
  
  def directory?
    File.directory?(@raw_path)
  end
  
  def folder?
    directory?
  end
  
  def file?
    not directory?
  end
  
  def basename
    File.basename(@raw_path)
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
      File.dirname(relative_path)
    else
      relative_path
    end
  end
  
  def is_folder_index?
    is_blacklisted = @raw_path.includes_one_of?(@config.no_index_folders) or blacklisted?
    directory? and !is_blacklisted
  end
  
  def index?
    has_index_in_path = (basename.include?("index.") or basename.include?("index_"))
    has_processable_extension = extension.includes_one_of?(@config.processable_extensions)
    (has_index_in_path and has_processable_extension) or is_folder_index?
  end

  def extension
    File.extname(@raw_path)
  end
  
  def output_extension
    if no_render?
      return extension
    else
      if @output_extension.nil?
        preprocess!
      end
    end
    @output_extension
  end
  
  def no_render?
    @config.no_render.include?(@raw_path)
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
  
  def text?
    [:haml, :textile, :markdown, :plaintext].include?(file_type) # :html as well?
  end
  
  # Used for pagination. Only one catalog per file is allowed to paginate.
  # @fc_start will be -1 for pagination.
  # @fc_count will be 0 for "show all," which is contrary to pagination.
  def get_first_catalog_info!
    @fc_folder, @fc_start, @fc_count, @fc_blocks, @fc_block_template, @fc_category, @fc_sort_by, @fc_deep = extract_first_catalog raw_contents
  end

  def num_pages
    if @num_pages.nil?
      if paginate?
        source_file_cache = @site_cache.cache[@fc_folder]
        
        filtered_items = source_file_cache.filtered_children(@fc_category) # Attempt to filter.
        
        num_items = filtered_items.length
        
        @num_pages = (num_items.to_f / @fc_count.to_f).ceil # round up
      else
        @num_pages = 1
      end
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
    if @paginate.nil?
      
      if processable?
        
        if @fc_start.nil?
          get_first_catalog_info!
          
          if @fc_start == -1 # Magic number!
            @paginate = true
          else
            @paginate = false
          end
        end
      
      else
        @paginate = false
      end
    end
    @paginate
  end

  def page_links
    if @page_links.nil?
      if paginate?
        @page_links = render_page_links(num_pages, file_join(@config.link_root, @raw_path), @page)
      else
        @page_links = ""
      end
    end
    @page_links
  end

  def preprocess!
    return if @preprocessed
    
    # ------ Pagination ------
    offset = (@page - 1) * items_per_page
    # Only the first INSERTCATALOG is paginated, since the items_per_page only comes
    # from the first one found.
    @process_contents = process_contents.gsub("PAGINATE", offset.to_s)

    # Insert contents before extracting the categories, template, and images...
    # This inserts the raw contents of a file. The format must be the same as the parent.
    @process_contents = insert_contents(process_contents, site_cache, current_path)
    
    @process_contents = insert_linkroot(process_contents, @config.link_root)
    @process_contents = insert_blog_dir(process_contents, @config.blog_dir)

    # ----------------- Extractions --------------------
    @render_slideshow, @process_contents = should_render_slideshow?(process_contents)
    @categories, @process_contents = extract_categories(process_contents)
    @template, @process_contents = extract_template(process_contents)
    @images, @process_contents = extract_images(process_contents)
    @process_contents = insert_thumbnails(process_contents)
    
    @post_title, @process_contents = extract_title(process_contents, file_type, @config)
    if @post_title.blank?
      @post_title = extract_title_from_filename(@raw_path)
    end
    
    @raw_post_date, @process_contents = extract_date(process_contents)
    if @raw_post_date.blank?
      # YYYY/MM/DD/title-here.md or YYYY/MM/DD-title-here.md
      @raw_post_date = extract_date_from_folder_structure(@raw_path)
    end
    if @raw_post_date.blank?
      # YYYY-MM-DD-title-here.md
      @raw_post_date = extract_date_from_filename(@raw_path)
    end
    if @raw_post_date.blank?
      # Modification time.
      if File.exists?(@raw_path) # This may be generated, not an on-disk file.
        @raw_post_date = File.mtime(@raw_path).strftime("%Y-%m-%d")
      end
    end
    if @raw_post_date.blank?
      @raw_post_date = Time.now.strftime("%Y-%m-%d")
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
    
    @sidebar_contents, @process_contents = extract_sidebar_contents process_contents, @config
    @sidebar_contents = render(@sidebar_contents, file_type)
    
    # Replace LINKROOT and CURRENTPATH once all the other content has been inserted...
    # TODO: Make sure CURRENTPATH is working properly.
    #@process_contents = insert_currentpath process_contents, file_join(@config.link_root, path_to)

    @process_contents = insert_linkroot process_contents, @config.link_root
    @process_contents = insert_blog_dir process_contents, @config.blog_dir
    
    # Generated content ...
    @breadcrumb = render_breadcrumb self, @categories
    @html_title = build_title @raw_path, @config.site_name, @post_title
    @gallery = render_gallery @images, @config
    
    @preprocessed = true
  end
  
  def preprocessed_contents
    preprocess!
    @process_contents
  end

  def rendered_contents
    @rendered_contents ||= render_with_insertions(process_contents, file_type, @config)
  end
  
  def rendered_contents_with_demoted_headers
    @rendered_contents_demoted ||= render_with_insertions(
      demote_headers(process_contents, file_type), file_type, @config
    )
  end

  def excerpt_contents
    return calculate_excerpt(rendered_contents)
  end

  def excerpt_contents_demoted
    return calculate_excerpt(rendered_contents_with_demoted_headers)
  end

  def calculate_excerpt(str, num_paragraphs=4)
    str = str.gsub(/<aside>.*?<\/aside>/m, "").strip()
    positions = str.enum_for(:scan, /<p[^>]*>.*<\/p>/).map { Regexp.last_match.begin(0) }
    if positions.length > num_paragraphs
      end_pos = positions[num_paragraphs]
      tr = str[0...end_pos]
      return tr
    else
      return str
    end
  end

  def first_paragraph
    if @first_paragraph.nil? or @raw_first_paragraph.nil?
      @raw_first_paragraph = ""
      @first_paragraph = ""
      
      # Wren controls the content of auto-generated indices, and so we don't
      # want to hoist the first paragraph here.
      if processable? and not is_folder_index?
        html_pattern = /<p\b[^>]*>([.\w\s\n\.\"\/\(\)\*'&;:<>,-_!]+?)<\/p>/
        
        m = rendered_contents.match(html_pattern)
        
        if not m.nil?
          @raw_first_paragraph = m[0]
          @first_paragraph = m[1]
        else
          @raw_first_paragraph = ""
          @first_paragraph = ""
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
  
  # TODO: update with new configurable image sizes.
  # @config.thumbnails.keys
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
        :sidebar_contents => sidebar_contents,
        :sidebar => sidebar_contents,
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
        :description => description.blank? ? first_para : description,
        :preview => @config.preview?,
        :javascript_paths => javascript_paths
      }.update(@config.config_dict)).update(first_image_thumbnails)
    end
    @attributes
  end

  # Handle the layout. Calls 'rendered_contents' and triggers the update.
  def html_contents
    LayoutHandler.new(self).wrap_with_layout
  end

  def contents
    @contents ||= processable? ? html_contents : nil
  end
end

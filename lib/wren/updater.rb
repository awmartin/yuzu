require 'pathname'
require 'stringio'
require 'haml'
require 'RedCloth'
require 'prawn'
require 'suppressor'

require 'renderers/pdf_renderer'
require 'renderers/textile_renderer'
require 'renderers/haml_renderer'
require 'renderers/keyword_handlers'
require 'renderers/layout'
require 'renderers/page_links'
require 'content_handlers'

require 'wren_config'

class PageInfo
  attr_accessor :link_root
  attr_accessor :html_title
  attr_accessor :post_title
  attr_accessor :site_name
  attr_accessor :file_type
end

class Updater
  
  # Pass in a fully initialized Uploader object.
  def initialize uploader_obj, config_dict
    return if uploader_obj.nil?
    return if config_dict.length == 0
    
    @uploader = uploader_obj
    @config = WrenConfig.new(config_dict)

    @local_relative_path = "."
    @pageinfo = PageInfo.new
    
    @pageinfo.link_root = @config.link_root_for_service(@uploader.service)
    @pageinfo.html_title = @config.site_name
    @pageinfo.site_name = @config.site_name
    
    @suppressor = Suppressor.new
    
    # Key to text contents.
    @site_cache = {}
    
    puts "Updater initialized..."
  end
  
  
  # Recusive loop to rebuild the entire site.
  def update_all current_location="."
    puts "Updating all..."
    
    Dir.foreach(current_location) do |filename|
      # Exclude ".", "..", hidden folders, and partials.
      
      if filename[0].chr != "." and filename[0].chr != "_"
        file_path = concat_path(current_location, filename)
        
        # Don't traverse the folders blacklist at all.
        if File::directory?(file_path) and not file_path.includes_one_of?(@config.folder_blacklist)
          
          # Attempt to render the index first, but don't render the auto-generated index if
          # the folder is part of the no_index_folders list.
          unless file_path.includes_one_of?(@config.no_index_folders)
            update_path(file_path, false)
          end
          
          # Duplicates the index if it exists, but that's ok.
          update_all(file_path)
          
        elsif @config.processable?(file_path)
          
          # Update without updating dependants. This method update_all isn't for changes per se, 
          # it's for generating the entire set of HTML files, like a forced render of the whole site.
          update_path(file_path, false)
          
        elsif file_path.to_s.includes_one_of?(@config.resource_extensions)
          
          # If the file is a resource, like a javascript or css file, upload it.
          puts "Opening #{file_path} for upload."
          file = File.open(file_path, "r")
          upload_file(file_path, file)
          
        end
      end
    end
  end
  
  # Takes an array of file extensions and traverses the file structure to upload them. It also collects all the
  # file names into an array and returns it.
  # @param extensions Array of Strings: Extensions for the files to upload raw, without processing of any kind.
  def upload_all_files_of_types current_location=".", extensions=[], list=[], new_only=false, catalog=[]
    Dir.foreach(current_location) do |filename|
      # Exclude ".", "..", hidden folders, and partials.
      
      if filename[0].chr != "." and filename[0].chr != "_"
        file_path = concat_path(current_location, filename)
        
        if File::directory?(file_path) and not @config.folder_blacklist.include?(file_path)
          
          # Update files with these extensions recursively.
          list += upload_all_files_of_types(file_path, extensions, [], new_only, catalog)
          
        elsif file_path.includes_one_of?(extensions)
          
          if !new_only or (new_only and !catalog.include?(file_path))
            puts "Opening #{file_path} for upload."
            file = File.open(file_path, "r")
            upload_file(file_path, file)
            
            list += [file_path]
          end
          
        end
      end
    end
    
    return list
  end
  
  def upload_new_images known_images=[], current_location="."
    return upload_all_files_of_types(current_location, @config.image_extensions, [], true, known_images)
  end
  
  def upload_all_images current_location="."
    return upload_all_files_of_types(current_location, @config.image_extensions)
  end
  
  def upload_all_assets current_location="."
    return upload_all_files_of_types(current_location, @config.asset_extensions)
  end
  
  def upload_all_resources current_location="."
    return upload_all_files_of_types(current_location, @config.resource_extensions)
  end
  
  # One point of exit for the process to upload the file to the proper location.
  # The Uploader object keeps track of the destination and the service (s3, filesystem, etc.).
  def upload_file local_path="", contents=""
    return if local_path.blank? or contents.blank?
    
    puts "Uploading #{local_path}"
    
    if @config.processable?(local_path)
      # Convert the local path file extension to HTML.
      ext = File.extname(local_path)
      html_path = local_path.sub(ext, ".html")
      @uploader.upload(html_path, contents)
    else
      @uploader.upload(local_path, contents)
    end
    
  rescue => exception
    puts "Updater#upload_file exception..."
    puts exception.message
    puts exception.backtrace
  end
  

  # Rendering methods..........................................
  
  def update_preview
    @uploader.set_preview
    @pageinfo.link_root = @config.link_root_for_service('preview')
  end
  
  # Update a particular list of files, presented as an array.
  def update_these array_of_files=[]
    
    array_of_files.each do |local_path|
      ext = File.extname(local_path)
      
      # Upload resources, images, and assets
      if ext.includes_one_of?(@config.resource_extensions + @config.image_extensions + @config.asset_extensions)
        
        puts "Uploading #{local_path}."
        file = File.open(local_path,"r")
        upload_file(local_path, file)
        
      else
        
        if !ext.includes_one_of?(@config.extension_blacklist)
          update_path(local_path, true)
        end
        
      end
    end
  end
  
  # Update this file first.
  # Look for files that depend on this one... Update them.
  # @param file_path String Should be the *relative* path for the file.
  def update_path local_path, should_update_dependants=false
    puts "\nUpdater#update_path-------- Attempting to update: #{local_path}"
    
    # These are the variables we're trying to populate.
    file = nil
    contents = ""
    metadata = {}
    
    if File::directory?(local_path)
      
      puts "Rendering a folder, so generating an index."
      
      file, new_path = render_index(local_path) # file is a StringIO
      template = "_index.haml"
      
    elsif @config.processable?(local_path)
      
      puts "Opening: #{local_path}"
      file = File.open(local_path, 'r')
      new_path = local_path.dup
      template = "_generic.haml"
      
    else
      # Do nothing.
      puts "Not handling #{local_path}."
      return
    end
    
    # Here we have the file.
    # Need contents, template, metadata
    # And also the results of INSERTCATALOG to determine pagination.


    if file.is_a?(StringIO) or (file.is_a?(File) and file.path.to_s.include?('index.'))
      # If we've been given a StringIO, then something else has generated the
      # file contents, like rendering a custom index.html file. Just read the
      # contents out of the StringIO wrapper.
      
      puts "Found a StringIO or an index."
      
      raw_lines = file.readlines
      raw_contents = raw_lines.join
      catalog_path, start_pos, count, num_blocks_per_row, block_template = extract_first_catalog(raw_contents)
      puts ">>>> start_pos is #{start_pos}, count is #{count}"
      
      if catalog_path.nil? or start_pos != -1
        # Don't paginate
        puts "  Not paginating: new_path = #{new_path}"
        contents, template, metadata = process_file(file, new_path)
        file.close
        puts "  local_path is #{local_path}, new_path is #{new_path}"
        wrap_and_process(contents, template, metadata, local_path, new_path, should_update_dependants)
        return
      else
        file.close
        puts "  Paginating: #{new_path}"
        
        # Getting the entries to paginate. Just to count how many there are.
        # The INSERTCONTENTS directive will find them (again!) when the page is rendered.
        entries = get_catalog_contents(catalog_path)
        
        # Paginate
        num_entries = entries.length
        num_pages = [1, (num_entries.to_f / count.to_f).ceil.to_i].max
        puts "  num_pages is #{num_pages}"
        
        file_type = get_file_type(@config, file)
        
        num_pages.times do |page_number|
          puts ">>>>> Rendering page #{page_number+1}."
          offset = page_number * count
          page_contents = raw_contents.gsub("PAGINATE", offset.to_s)
          puts "page_contents is #{page_contents}"
          
          if page_number == 0
            page_path = new_path.dup
          else
            page_path = new_path.gsub("index.", "index_#{page_number+1}.")
          end
          
          contents, template, metadata = process_contents(page_contents, file_type, page_path)
          metadata[:page_links] = render_page_links(num_pages, concat_path(@pageinfo.link_root, page_path), page_number+1)
          # Process the page.
          wrap_and_process(contents, template, metadata, page_path, page_path, should_update_dependants)
        end
        
        return
      end
      
    else
      puts "  Regular parsing. No pagination."
      # Regular parsing. No pagination.
      contents, template, metadata = process_file(file, new_path)
      file.close
      wrap_and_process(contents, template, metadata, local_path, new_path, should_update_dependants)
      return
    end
  end
  
  
  def wrap_and_process contents, template, metadata, local_path, new_path, should_update_dependants=false
    puts "wrap_and_process: local_path = #{local_path}, new_path = #{new_path}"
    
    metadata.update({:breadcrumb_path => local_path})
    if not metadata.has_key?(:post_title)
      metadata.update({:post_title => extract_title_from_filename(local_path)})
    else
      if metadata[:post_title].blank?
        metadata.update({:post_title => extract_title_from_filename(local_path)})
      end
    end
    
    wrapped_contents = LayoutHandler.new(@config, @pageinfo).wrap_with_layout(contents, template, metadata)
    
    post_process(new_path, wrapped_contents, should_update_dependants)
  end
  
  
  # Just pass File objects that have already been opened. This actually converts the textile 
  # and haml files into their HTML counterparts.
  #
  # @param file - StringIO or File that contains the instructions to render.
  # @param file_path - The path of the file being rendered. Either file.path or something manually given.
  # @returns String The rendered HTML contents.
  def process_file file=nil, file_path=""
    return "Updater#process_file received a nil file." if file.nil?
    return "Updater#process_file received an empty path string" if file_path.blank?
    
    puts "Processing contents of #{file_path}..."
    
    file.rewind
    
    @pageinfo.html_title = build_title(file_path, @pageinfo)
    puts "html_title is #{@pageinfo.html_title}"
    
    if file.is_a?(File)
      @pageinfo.file_type = get_file_type(@config, file)
    elsif file.is_a?(StringIO)
      @pageinfo.file_type = :haml
    end
    puts "file_type is #{@pageinfo.file_type}"
    
    contents = file.readlines.join
    
    return process_contents(contents, @pageinfo.file_type, file_path)
    
  rescue => detail
    puts "EXCEPTION in process_file..."
    puts detail.message
    puts detail.backtrace
    return ""
  end
  
  
  def process_contents contents, file_type, file_path
    puts "process_contents got #{file_type} for #{file_path}"
    
    # Handle files.
    if file_type == :asset or file_type == :image
      # Images and other binary files... Do nothing.
      
    elsif file_type == :plaintext
      puts "Plain text or code found."
      return contents, "_generic.haml", {}
    
    elsif file_type == :textile
      # Catches ".text" and ".textile" extensions.
      puts "Textile file found."
      return render_textile(contents, file_path)
      
    elsif file_type == :html
      puts "HTML file found."
      return contents, "_generic.haml", {}
      
    elsif file_type == :haml
      puts "HAML file found."
      return render_haml(contents, file_path)
      
    else
      puts "Unprocessable file found."
      return contents, "_generic.haml", {}

    end
  end
  
  # Renders index files, including folders that don't contain index.*.
  # This preferences index.text, then index.textile, then index.haml, then 
  # index.html. If none of them are found, then it generates an index.html 
  # file by creating an html page, including an unordered list of links to 
  # the included folders and files.
  def render_index folder_path
    file = nil
    file_path = folder_path
    
    index, index_path = open_index(folder_path)
    
    if index.blank? and not folder_path.includes_one_of?(@config.no_index_folders)
      # Generate a new, customized index.html file, as a list of links.
      puts "Didn't find an index file. Generating a custom one from folder's contents: #{file_path}"
      
      @pageinfo.html_title = build_title(file_path, @pageinfo)
      str = render_list_index(file_path)
      index = StringIO.new(str)
      index_path = File.join(folder_path, "index.html")
    end
    
    puts "Returning from render_index: #{index_path.to_s}"
    return index, index_path
  end
  
  # Attempts to locate and open an index.* file in the given folder.
  def open_index folder_path=""
    ["index.text", "index.textile", "index.haml", "index.html"].each do |index_filename|
      
      index_path = File.join(folder_path, index_filename)
      
      if File.exists?(index_path)
        index = File.open(index_path, 'r')
        return index, index_path
      else
        return nil, index_path
      end
    end
  
  rescue => exception
    puts "Exception in Updater#open_index"
    puts exception.message
    puts exception.backtrace
    return nil, folder_path.to_s
  end
  
  # Index pages are generated as a generic catalog. This happens when there is no index.text
  # or index.haml file found.
  def render_list_index path
    puts "Building an index page for path: #{path}"
    
    if not File::directory?( path )
      puts "  Error: Given path is not a directory."
      return ""
    end
    
    return "INSERTCATALOG(#{path},PAGINATE,10,3,_block.haml)"
    
    #return insert_catalog(path, {:blocks_per_row => 3}, @config, @pageinfo)
  end
  
  # This method handles the uploading process and updating dependants.
  def post_process local_path, contents, should_update_dependants=false
    puts "Post processing #{local_path}"
    
    # Combine and upload the contents to a file on the remote server.
    upload_file(local_path, contents)
    
    if should_update_dependants
      puts "Attempting to update dependants of file: #{local_path}"
      update_dependants(@local_relative_path, local_path)
      puts "Done with dependants for #{local_path}"
    end
  end
  
  # Loops through all the files in the site and looks for the presence of
  # "partial_path". If it exists, then force the update of the file in
  # which the partial_path appeared.
  # @param current_location String Should be the current path of the recursion
  # @param partial_path String The absolute path of the partial in question.
  def update_dependants current_location, partial_path
    print "."
    Dir.foreach(current_location) do |filename|
      # Exclude ".", "..", and hidden folders
      if filename[0].chr != "."
        file_path = File.join( current_location, filename )
        if File::directory?(file_path)
          update_dependants file_path, partial_path
        else
          if @config.processable?(file_path)
            # Check for the presence of partial_path in the contents of the file.
            file_handle = File.open(file_path,"r")
            file_contents = file_handle.readlines.join
            if file_contents.include? "INSERTCONTENTS(" + add_leading_slash(partial_path) + ")"
              puts "\n#{file_path} includes reference to #{partial_path}... Updating..."
              update_path(file_path, false)
            end
          end
        end
      end
    end
  rescue => detail
    puts detail.message
  end
  

  def render_pdf str, local_path=""
    html = render_textile(str, local_path)
    PDFRenderer.new(html).render(local_path)
  end
  
  def render_haml str, local_path
    return "", "_generic.haml", {} if str.blank?
    #@suppressor.shutup!
    #result = Haml::Engine.new(str, {:format => :html5}).render(Object.new, { :html_title => @html_title } )
    #@suppressor.ok
    return HamlRenderer.new(@config, @pageinfo).render(str, local_path)
  rescue => detail
    puts detail.message
    return ""
  end
  
  # We have to pass the path to the file (local_path) since we're replacing CURRENTPATH.
  def render_textile str="", local_path=""
    return "", "_generic.haml", {} if str.blank?
    return TextileRenderer.new(@config, @pageinfo).render(str, local_path)
  end

  # Inserts a <script> tag given the javascript name. This accepts either a full path
  # like http://apis.google.com/lib.... or a filename like accordion.js. It expects the
  # javascript file to be in the "javascripts" folder in the root of the file system.
  # It automatically prepends the javascripts/... for you.
  def insert_javascript filename
    if filename.include?("http://") or filename.include?("https://")
      js_file_path = filename
    else
      js_file_path = linked_path(@pageinfo, File.join("javascripts",filename))
    end
    
    return "<script src=\"#{js_file_path}\" type=\"text/javascript\" charset=\"utf-8\"></script>"
  end
  
  # Layout and content helpers ..................................................................


  def is_outline?
    false
  end

  def is_slideshow?
    false
  end
  
  def done
    @uploader.close unless @uploader.nil?
    @suppressor.close unless @suppressor.nil?
  end

end

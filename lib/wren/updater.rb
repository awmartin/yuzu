require 'pathname'
require 'stringio'
require 'haml'
require 'RedCloth'
require 'prawn'
require 'suppressor'
require 'renderers'
require 'liquid'

class Updater
  
  # Pass in a fully initialized Uploader object.
  def initialize uploader_obj, config
    return if uploader_obj.nil?
    return if config.length == 0
    
    @uploader = uploader_obj
    @config = config

    @local_relative_path = "."
    @link_root = @config[@uploader.service]['link_root'].to_s
    
    @site_name = @config['site_name']
    @page_title = @site_name
    @suppressor = Suppressor.new
    
    # Key to text contents.
    @site_cache = {}
    
    puts "Loading partials..."
    @html_head = load_partial "_head.haml"
    @header_contents = load_partial "_header.haml"
    @menu_contents = load_partial "_menu.haml"
    
    recents = get_recent_blog_posts
    titles = recents.collect {|entry| extract_title_from_filename entry}
    @footer_contents = load_partial "_footer.haml", {:recents => recents, :titles => titles}
    
    puts "Done with partials."
  end
  
  def get_recent_blog_posts
    if File.exists?(@config['blog_dir'])
      return get_catalog_contents(@config['blog_dir']).collect {|r| r.gsub(".text",".html")}
    else
      return []
    end
  rescue => detail
    return []
  end
  
  def processable? local_path=""
    return false if local_path.blank?
    ext = File.extname(local_path.to_s).to_s
    return (ext.includes_one_of?( processable_extensions ) and !ext.includes_one_of?( extension_blacklist ))
  end
  
  def use_strict_index_links
    @config['use_strict_index_links']
  end
  
  # Don't traverse these folders.
  def folder_blacklist
    @config['folder_blacklist']
  end
  
  def no_index_folders
    @config['no_index_folders']
  end
  
  def extension_blacklist
    @config['extension_blacklist']
  end
  
  def processable_extensions
    @config['processable_extensions']
  end
  
  def image_extensions
    @config['image_extensions']
  end
  
  def asset_extensions
    @config['asset_extensions']
  end
  
  def resource_extensions
    @config['resource_extensions']
  end
  
  def template_dir
    @config['template_dir']
  end
  
  
  # Like File.join, but cleans up the leading ./ in paths like
  # ./modules/index.text
  def concat_path prepath="", postpath=""
    Pathname.new( File.join( prepath, postpath ) ).cleanpath.to_s
  end
  
  # Recusive loop to rebuild the entire site.
  def update_all current_location="."
    
    Dir.foreach(current_location) do |filename|
      # Exclude ".", "..", hidden folders, and partials.
      
      if filename[0].chr != "." and filename[0].chr != "_"
        file_path = concat_path( current_location, filename )
        
        # Don't traverse the folders blacklist at all.
        if File::directory?(file_path) and not file_path.includes_one_of?( folder_blacklist )
          
          # Attempt to render the index first, but don't render the auto-generated index if
          # the folder is part of the no_index_folders list.
          unless file_path.includes_one_of?( no_index_folders )
            update_path file_path, false
          end
          
          # Duplicates the index if it exists, but that's ok.
          update_all file_path
          
        elsif processable?( file_path )
          
          # Update without updating dependants. This method update_all isn't for changes per se, 
          # it's for generating the entire set of HTML files, like a forced render of the whole site.
          update_path file_path, false
          
        elsif file_path.to_s.includes_one_of?( resource_extensions )
          
          # If the file is a resource, like a javascript or css file, upload it.
          puts "Opening #{file_path} for upload."
          file = File.open(file_path, "r")
          upload_file file_path, file
          
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
        file_path = concat_path( current_location, filename )
        
        if File::directory?(file_path) and not folder_blacklist.include? file_path
          
          # Update files with these extensions recursively.
          list += upload_all_files_of_types file_path, extensions, [], new_only, catalog
          
        elsif file_path.includes_one_of? extensions
          
          if !new_only or (new_only and !catalog.include?(file_path))
            puts "Opening #{file_path} for upload."
            file = File.open(file_path, "r")
            upload_file file_path, file
            
            list += [file_path]
          end
          
        end
      end
    end
    
    return list
  end
  
  def upload_new_images known_images=[], current_location="."
    return upload_all_files_of_types current_location, image_extensions, [], true, known_images
  end
  
  def upload_all_images current_location="."
    return upload_all_files_of_types current_location, image_extensions
  end
  
  def upload_all_assets current_location="."
    return upload_all_files_of_types current_location, asset_extensions
  end
  
  def upload_all_resources current_location="."
    return upload_all_files_of_types current_location, resource_extensions
  end
  
  # One point of exit for the process to upload the file to the proper location.
  # The Uploader object keeps track of the destination and the service (s3, filesystem, etc.).
  def upload_file local_path="", contents=""
    return if local_path.blank? or contents.blank?
    
    puts "Uploading #{local_path}"
    
    if processable?( local_path )
      # Convert the local path file extension to HTML.
      ext = File.extname(local_path)
      html_path = local_path.sub(ext, ".html")
      @uploader.upload html_path, contents
    else
      @uploader.upload local_path, contents
    end
    
  rescue => detail
    puts "Updater#upload_file exception..."
    puts detail.message
  end
  
  def build_cache
    
  end
  
  # Rendering methods..........................................
  
  def update_preview
    @uploader.set_preview
    @link_root = @config['preview']['link_root'].to_s
  end
  
  # Update a particular list of files, presented as an array.
  def update_these array_of_files=[]
    
    array_of_files.each do |local_path|
      ext = File.extname(local_path)
      
      # Upload resources, images, and assets
      if ext.includes_one_of?( resource_extensions + image_extensions + asset_extensions )
        
        puts "Uploading #{local_path}."
        file = File.open(local_path,"r")
        upload_file local_path, file
        
      else
        
        if !ext.includes_one_of?( extension_blacklist )
          update_path local_path, true
        end
        
      end
    end
  end
  

  # Update this file first.
  # Look for files that depend on this one... Update them.
  # @param file_path String Should be the *relative* path for the file.
  def update_path local_path, update_all=false
    puts "\n------"
    puts "Attempting to update: #{local_path}"
    
    # These are the two variables we're trying to populate.
    file = nil
    contents = ""
    metadata = {}
    
    if File::directory? local_path
      
      puts "Rendering a path, generating an index."
      file, new_path = render_index( local_path )
      
    elsif processable? local_path
      
      puts "Opening: #{local_path}"
      file = File.open(local_path, 'r')
      new_path = local_path
      
    else
      # Do nothing.
      puts "Not handling #{local_path}."
      return
    end
    
    if file.is_a? StringIO
      # If we've been given a StringIO, then something else has generated the
      # file contents, like rendering a custom index.html file. Just read the
      # contents out of the StringIO wrapper.
      contents = file.readlines
      template = "_generic.haml"
    else
      # Hand the file over to be processed, which includes conversion to HTML.
      contents, template, metadata = process_file( file )
      file.close
    end
    
    metadata.update({:breadcrumb_path => local_path,
                    :post_title => extract_title_from_filename(local_path)
                    })
    post_process new_path, wrap_with_layout(contents, "", template, metadata), update_all
  end
  
  # Index pages are generated as an unordered list of links to all the folders
  # and files inside a parent folder. This happens when there is no index.text
  # or index.haml file found.
  def render_list_index path
    return "" if not File::directory?( path )
    puts "Building an index page for path: #{path}"
    
    #@page_title = build_title path
    @html_head = load_partial "_head.haml"
    
    #text = "<h1>#{@page_title}</h1>"
    text = insert_catalog path
    
    #puts "Returning from render_list_index with #{text.length}"
    return text
  end
  
  # Renders index files, including folders that don't contain index.*.
  # This preferences index.text, then index.textile, then index.haml, then 
  # index.html. If none of them are found, then it generates an index.html 
  # file by creating an html page, including an unordered list of links to 
  # the included folders and files.
  def render_index folder_path
    file = nil
    file_path = folder_path
    
    index, index_path = open_index folder_path
    
    if index.blank? and not folder_path.includes_one_of?( no_index_folders )
      # Generate a new, customized index.html file, as a list of links.
      puts "Didn't find an index file. Generating a custom one from folder's contents: #{file_path}"
      str = render_list_index file_path
      index = StringIO.new(str)
      index_path = File.join( folder_path, "index.html")
    end
    puts "Returning from render_index: #{index_path.to_s}"
    return index, index_path
  end
  
  def open_index folder_path=""    
    # Do index.text
    index_path = File.join(folder_path, "index.text")
    index = File.open(index_path,'r') rescue nil
    
    if index.blank?
      index_path = File.join(folder_path, "index.textile")
      index = File.open(index_path,'r') rescue nil
      
      if index.blank?
        index_path = File.join(folder_path, "index.haml")
        index = File.open(index_path,'r') rescue nil
        
        if index.blank?
          index_path = File.join(folder_path, "index.html")
          index = File.open(index_path,'r') rescue nil
        end
      end
    end
    
    return index, index_path
  end
  
  def extract_first_paragraph file
    paragraph = ""
    headers = /h1\.\s|h2\.\s|h3\.\s|h4\.\s/
    past_first_header = false
    
    file.rewind
    # Sometimes, the files have INSERTCONTENTS for their primary contents.
    str = file.readlines.join("\n")
    contents = insert_contents str
    lines = contents.split("\n")
    
    # Check to see if there is a header at all...
    # TODO: Really should check to see if a paragraph shows up before a header.
    if contents.match(/h2\.\s/).nil?
      past_first_header = true
    end
    
    lines.each do |line|
      if past_first_header and not line.strip.blank? and line.strip[0].chr != "!" and line.match(headers).blank?
        paragraph = line.to_s.gsub("\n","").strip
        break
      end
      
      if not line.match(headers).blank? and not past_first_header
        past_first_header = true
      end
    end
    
    # Remove p(class). from the found paragraph.
    paragraph.gsub!(/p\([A-Za-z0-9\s]*\)\.\s/,"")
    
    return paragraph
  end
  
  def extract_first_image file
    file.rewind
    
    # Sometimes, the files have INSERTCONTENTS for their primary contents.
    str = file.readlines.join("\n")
    contents = insert_contents str
    lines = contents.split("\n")
    
    lines.each do |line|
      matches = line.match(/IMAGES\(([A-Za-z0-9\,\.\-\/_]*)\)/)
      if not matches.nil?
        m = matches[0].gsub("IMAGES(","").gsub(")","")
        image = m.split(",")[0]
        return image
      end
    end
    return ""
  end
  
  def extract_title_from_filename filename
    post_filename = filename.split("/").last
    if post_filename.include?("index")
      post_filename = filename.split("/")[-2]
      if post_filename.blank?
        post_filename = "Home"
      end
    end
    # Regex removes the leading date for posts, e.g. 2011-05-28-
    return titleize( post_filename.sub(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/,"") )
  end
  
  def extract_date_from_filename filename
    post_filename = filename.split("/").last
    if not post_filename.match(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/).nil?
      months = {"01" => "January","02" => "February", "03" => "March", "04" => "April", "05" => "May", "06" => "June",
                "07" => "July", "08" => "August", "09" => "September", "10" => "October", "11" => "November", "12" => "December"}
      date_parts = post_filename.split("-")[0..2]
      post_date = date_parts[0].to_s + " " + months[date_parts[1]] + " " + date_parts[2].to_s
      return post_date
    else
      return ""
    end
  end
  
  def get_catalog_contents path="", options={}
    default_options = {
      :ordered => false,
      :class => "",
      :count => 12,
      :start => 0,
      :sort_by => :name,
      :block_template => "_block.haml",
      :blocks_per_row => 1,
      :exclude_paths => []
    }
    options = default_options.dup.update(options)
    
    entries = Dir[File.join(path,"*")] # Just lists filenames and directory names
    
    # Traverse one folder deep.
    entries.each do |entry|
      subpath = entry
      if File.directory?(subpath)
        subpath_entries = Dir[File.join(subpath, "*")]
        entries += subpath_entries
      end
    end
    
    puts "#{entries.length} entries found."
    #entries.delete_if {|e| e[0].chr == "."}
    if options[:sort_by] == :name
      sorted = entries.sort.reverse
    elsif options[:sort_by] == :modified
      sorted = entries.collect { |f|
        [test(?M, f), f]
      }.sort.collect { |f| f[1] }
    end
    
    # Attempt to exclude toublemakers... Do this before the list slicing...
    sorted = sorted.reject {|p| p.include?("index.") or File.directory?(p)}
    #and not options[:exclude].include?(File.basename(entry_path))
    
    count = options[:count]
    if count > 0
      sorted = sorted[0...count]
    end
    return sorted
  end
  
  # Give it a path, and it returns a string consisting of a list of links and first paragraphs.
  # TODO Allow for the contents to be styled, adding css classes to the list items.
  # TODO Add functionality to include images. (Grab the first image tag?)
  def insert_catalog path="", options={}
    return "" if path.blank?
    return "" if not File.directory? path
    puts "Inserting catalog for: #{path}"
    
    default_options = {
      :ordered => false,
      :class => "",
      :count => 12,
      :start => 0,
      :sort_by => :name,
      :block_template => "_block.haml",
      :blocks_per_row => 1,
      :exclude_paths => [],
      :exclude_indicies => false
    }
    options = default_options.dup.update(options)
    
    tag = "ul"
    if options[:ordered]
      tag = "ol"
    end
    
    css_class = ""
    if not options[:class].blank?
      css_class = " class=\"#{options[:class]}\""
    end
    
    sorted = get_catalog_contents path, options
    
    text = ""
    
    sorted.each_index do |i|
      if i >= options[:start] 
        entry_path = sorted[i]
        puts "Processing catalog item: #{entry_path}"
        j = i-options[:start]
      
        if j%options[:blocks_per_row] == 0
          text += "<hr />\n"
        end
        
        post_title = extract_title_from_filename File.join(path, entry_path)
        
        # Extract the date.
        post_date = extract_date_from_filename entry_path
        
        if File.directory?( entry_path )
          # Locate the index.
          index, index_path = open_index entry_path
          if index.blank?
            paragraph = ""
            image_path = ""
          else
            paragraph = extract_first_paragraph index
            image_path = extract_first_image index
            contents = paragraph
            index.close
          end
        else
          if processable? entry_path
            file = File.open( entry_path, "r" )
            paragraph = extract_first_paragraph file
            image_path = extract_first_image file
            
            file.rewind
            lines = file.readlines
            contents, template, meta = render_textile lines.join("\n"), file.path, {:galleries => false, :strip_styles => true}
            file.close
          end
        end
        
        linkroot = remove_trailing_slash(@link_root)
        image_path.gsub!("LINKROOT", linkroot)
        image_path_small = image_path.gsub(".","-small.")
        image_path_medium = image_path.gsub(".","-medium.")
        image_path_large = image_path.gsub(".","-large.")
        
        # Build the URL for the link.
        link_url = File.join(@link_root, entry_path.gsub(".text",".html"))
        # Add a slash to the ends of folder urls. Makes java applets work.
        link_url += "/" if File.directory?( entry_path ) and entry_path[-1].chr != "/"
      
        if File.directory?( link_url ) and use_strict_index_links
          link_url = File.join( link_url, "index.html" )
        end
      
        #str = "<li><h3><a href=\"#{linked_path(html_path(link_url))}\">#{name}</a></h3>"
        #str += "#{paragraph}" unless paragraph.blank?
        #str += "</li>\n"
      
        str = load_template options[:block_template], { :post_title => post_title,
                                                        :post_date => post_date,
                                                        :contents => contents,
                                                        :first_paragraph => paragraph,
                                                        :image_path => image_path,
                                                        :image_path_small => image_path_small,
                                                        :image_path_medium => image_path_medium,
                                                        :image_path_large => image_path_large,
                                                        :klass => j%options[:blocks_per_row] == options[:blocks_per_row]-1 ? "last" : "",
                                                        :link_url => link_url,
                                                        :link_root => @link_root }
      
        text += str + "\n"
      end
    end
    
    return text
  rescue => detail
    puts detail.message
    return "Error in insert_catalog..."
  end
  
  def insert_listing path="", options={}
    
  end
  
  # This method handles the uploading process and updating dependants.
  def post_process local_path, contents, update_all=false
    puts "Post processing #{local_path}"
    
    # Combine and upload the contents to a file on the remote server.
    upload_file local_path, contents
    
    if update_all
      puts "Attempting to update dependants of file: #{local_path}"
      update_dependants @local_relative_path, local_path
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
          if processable? file_path
            # Check for the presence of partial_path in the contents of the file.
            file_handle = File.open(file_path,"r")
            file_contents = file_handle.readlines.join
            if file_contents.include? "INSERTCONTENTS(" + add_leading_slash(partial_path) + ")"
              puts "\n#{file_path} includes reference to #{partial_path}... Updating..."
              update_path file_path, false
            end
          end
        end
      end
    end
  rescue => detail
    puts detail.message
  end
  
  # Just pass File objects that have already been opened. This actually converts the textile 
  # and haml files into their HTML counterparts. 
  # @returns String The rendered HTML contents.
  def process_file file=nil
    return "" if file.nil?
    
    puts "Processing contents of #{file.path}..."
    
    @page_title = build_title file.path
    
    file_ext = File.extname( file.path )
    contents = file.readlines.join
    
    # Reload the head to refresh. Probably a better way using regex to replace what's needed...
    @html_head = load_partial "_head.haml"
    @menu_contents = load_partial "_menu.haml"
    
    # Handle files.
    if file_ext.includes_one_of?( image_extensions + asset_extensions )
      # Images and other binary files... Do nothing.
      
    elsif file_ext.includes_one_of? ["txt","pde","rb"]
      puts "Plain text or code found."
      
      return contents, "_generic.haml", {}
    else
      
      if file_ext.include? 'text'
        # Catches ".text" and ".textile" extensions.
        puts "Textile file found."
        return render_textile( contents, file.path )
        
      elsif file_ext.include? 'html'
        puts "HTML file found."
        return contents, "_generic.haml", {}
        
      elsif file_ext.include? 'haml'
        puts "HAML file found."
        return render_haml( contents ), "_generic.haml", {}
        
      else
        puts "Unprocessable file found."
        return contents, "_generic.haml", {}
        
      end
    
    end
    
  rescue => detail
    puts "EXCEPTION in process_file..."
    puts detail.message
    return ""
  end
  
  def load_template local_path="", data={}
    return "" if local_path.blank?
    local_path = File.join(template_dir, local_path).to_s
    puts "Loading template " + local_path.to_s
    
    template = File.open(local_path, 'r')
    contents = template.readlines.join
    
    #@suppressor.shutup!
    result = Haml::Engine.new(contents).render(Object.new, data)
    
    #  { 
    #    :head => @html_head,
    #    :menu => @menu_contents,
    #    :content => data.has_key?(:contents) ? data[:contents] : "",
    #    :header => @header_contents,
    #    :footer => @footer_contents
    #  })
    #@suppressor.ok
    
    return result
  rescue => detail
    puts detail.message
    return ""
  end
  
  # Loads the HAML partials for the layout. Especially _head.haml, _header.haml, 
  # _footer.haml, _menu.haml.
  def load_partial local_path="", data={}
    return "" if local_path.blank?
    local_path = File.join(template_dir, local_path).to_s
    
    puts "Loading partial #{local_path}."
    partial = File.open(local_path, 'r')
    contents = partial.readlines.join
    crumbs = data.has_key?(:path) ? render_breadcrumb(data[:path]) : ""
    
    @suppressor.shutup!
    result = Haml::Engine.new(contents).render(Object.new, 
      { 
        :page_title => @page_title,
        :link_root => @link_root,
        :breadcrumb => crumbs
      }.update(data))
    @suppressor.ok
    
    return result
  rescue => detail
    puts detail.message
    return ""
  end
  
  # Simple helper for grabbing the contents of a text file.
  # Used for the direct insertion of content with INSERTCONTENTS(...)
  # This defaults to a path absolute to the root of the file system,
  # which might not make sense...
  def insert_file local_path
    file = File.open(local_path, "r")
    return file.readlines.join
  rescue
    return ""
  end
  
  def render_pdf str, local_path=""
    html = render_textile str, local_path
    
    PDFRenderer.new(html).render(local_path)
  end
  
  def render_haml str
    @suppressor.shutup!
    result = Haml::Engine.new(str).render(Object.new, { :page_title => @page_title } )
    @suppressor.ok
    return result
  rescue => detail
    puts detail.message
    return ""
  end
  
  # We have to pass the path to the file (local_path) since we're replacing CURRENTPATH.
  def render_textile str="", local_path="", options={}
    return "" if str.blank?
    
    default_options = {
      :galleries => true,
      :strip_styles => false
    }
    options = default_options.dup.update(options)
    
    path_to_file = Pathname.new( path_to(local_path) ).cleanpath.to_s
    
    puts "Rendering textile for #{local_path}..."
    
    # Handle INSERTCONTENTS directives first...
    str = insert_contents str
    
    if options[:strip_styles]
      str.gsub!(/p\([A-Za-z0-9]*\)\.\s/,"")
    end
    
    # Look for images.
    images = []
    str.gsub!(/IMAGES\(([A-Za-z0-9\,\.\-\/_]*)\)/) do |s|
      images_str = s.gsub("IMAGES(","").gsub(")","")
      images += images_str.split(",")
      ""
    end
    
    # Look for galleries and insert images.
    str.gsub!("INSERTGALLERY") do |s|
      if options[:galleries]
        url = images.first
        url.gsub!(".","-large.")
        "<div class=\"slideshow\">\n<div class=\"slide\">\n!#{url}!\n</div>\n</div>"
      else
        ""
      end
    end
    
    # Look for template specification.
    template = "_generic.haml"
    str.gsub!(/TEMPLATE\(([A-Za-z0-9\.\-\/_]*)\)/) do |s|
      template = s.gsub("TEMPLATE(","").gsub(")","")
      ""
    end
    
    # Find any sidebar contents.
    sidebar_contents = ""
    str.gsub!(/SIDEBARCONTENTS\(\"[A-Za-z0-9\.\,\'\"\/\-_]*\"\)/) do |s|
      sidebar_contents = s.gsub("SIDEBARCONTENTS(\"","").gsub("\")","")
      ""
    end
    
    
    
    puts "Inserting catalogs..."
    str.gsub!(/INSERTCATALOG\(([A-Za-z0-9\,\.\-\/_]*)\)/) do |s|
      arg_str = s.gsub("INSERTCATALOG(","").gsub(")","")
      args = arg_str.split(",")
      
      # Extract the arguments.
      path_of_folder_to_insert = remove_leading_slash args[0].to_s
      start = args.length > 1 ? args[1].to_i : 0
      count = args.length > 2 ? args[2].to_i : 0
      blocks_per_row = args.length > 3 ? args[3].to_i : 3
      block_template = args.length > 4 ? args[4].to_s : "_block.haml"
      
      puts "Inserting catalog of #{path_of_folder_to_insert} with #{count} items (zero = all)."
      
      insert_catalog(path_of_folder_to_insert, {:ordered => true, 
                                                :class => "blocks", 
                                                :count => count,
                                                :start => start,
                                                :blocks_per_row => blocks_per_row,
                                                :block_template => block_template,
                                                :exclude => [File.basename(local_path)]})
    end
    
    # Build the CURRENTPATH value.
    # This depends on the location in the recursion. It can't be done like this really.
    current_relative_path = linked_path path_to_file
    puts "Replacing CURRENTPATH with #{current_relative_path}"
    str.gsub!("CURRENTPATH", current_relative_path)
    
    linkroot = remove_trailing_slash(@link_root)
    puts "Replacing LINKROOT with #{linkroot}"
    str.gsub!("LINKROOT", linkroot)
    
    puts "Replacing MULTIVIEW."
    if str.include?("MULTIVIEW")
      make_slideshow str.gsub("MULTIVIEW",""), local_path
      make_accordion str.gsub("MULTIVIEW",""), local_path
      str.gsub!( "MULTIVIEW", multiview(local_path) )
    end
    
    # Image url replacement. Not needed on an Apache server.
    #user_id = ENV['DROPBOX_ON_RAILS_USER_ID']
    #full_url = "http://dl.dropbox.com/u/#{user_id}#{APP_@config[:site_folder]}".gsub('/Public','')
    #str = replace_image_urls str, full_url
    
    return RedCloth.new(str).to_html, template, {}
  rescue => exception
    puts "EXCEPTION in Uploader#render_textile"
    puts exception.message
    puts exception.backtrace
    return ""
  end
  
  def insert_contents str
    str.gsub(/INSERTCONTENTS\(([A-Za-z0-9\.\-\/_]*)\)/) do |s|
      path_of_file_to_insert = remove_leading_slash s.gsub("INSERTCONTENTS(","").gsub(")","")
      puts "Inserting contents of #{path_of_file_to_insert}"
      insert_file(path_of_file_to_insert).gsub("MULTIVIEW","")
    end
  end
  
  def make_slideshow original_contents, local_path
    puts "--"
    puts "Generating the slideshow."
    
    # Render the slideshow view as well.
    slideshow = wrap_slides original_contents
    slideshow_contents = RedCloth.new(slideshow).to_html
    
    js = insert_javascript "slideshow.js"
    wrapped_contents = wrap_with_layout(slideshow_contents, js)
    wrapped_contents.gsub!("class='content'", "class='content slideshow'")
    
    post_process slideshow_path( local_path ), wrapped_contents
    
    puts "Done with slideshow."
    puts "--"
  end
  
  def make_accordion original_contents, local_path
    puts "--"
    puts "Generating the accordion."
    
    accordion = wrap_accordion original_contents
    accordion_contents = RedCloth.new(accordion).to_html
    
    js = insert_javascript "accordion.js"
    wrapped_contents = wrap_with_layout(accordion_contents, js)
    wrapped_contents.gsub!("class='content'", "class='content accordion'")
    
    post_process accordion_path( local_path ), wrapped_contents
    
    puts "Done with accordion."
    puts "--"
  end
  
  # Inserts a <script> tag given the javascript name. This accepts either a full path
  # like http://apis.google.com/lib.... or a filename like accordion.js. It expects the
  # javascript file to be in the "javascripts" folder in the root of the file system.
  # It automatically prepends the javascripts/... for you.
  def insert_javascript filename
    if filename.include?("http://") or filename.include?("https://")
      js_file_path = filename
    else
      js_file_path = linked_path File.join("javascripts",filename)
    end
    
    return "<script src=\"#{js_file_path}\" type=\"text/javascript\" charset=\"utf-8\"></script>"
  end
  
  # Layout and content helpers ..................................................................
  
  # Puts the header and footer in place.
  def wrap_with_layout contents="", js="", template="_generic.haml", meta={}
    puts "wrap_with_layout"
    
    first_paragraph = meta.has_key?(:first_paragraph) ? meta[:first_paragraph] : ""
    breadcrumb = meta.has_key?(:breadcrumb_path) ? render_breadcrumb(meta[:breadcrumb_path]) : ""
    post_title = meta.has_key?(:post_title) ? meta[:post_title] : "No Title"
    
    return load_template(template, {:head => @html_head, 
                                    :contents => contents,
                                    :header => @header_contents,
                                    :footer => @footer_contents,
                                    :menu => @menu_contents,
                                    :first_paragraph => first_paragraph,
                                    :breadcrumb => breadcrumb,
                                    :post_title => post_title})
    
#    pre = "<!DOCTYPE html>\n<html lang='en-US' xml:lang='en-US' xmlns='http://www.w3.org/1999/xhtml'>\n"
#    pre += @html_head.to_s
#    pre += "<body>\n"
#    pre += "<div class='container'>\n"
#    pre += "<div class='header'>#{@header_contents}#{@menu_contents}</div> <!-- header -->\n"
#    pre += "<div class='content'>#{contents}</div> <!-- content -->\n"
#    pre += "<div class='footer'>#{@footer_contents}</div> <!-- footer -->\n"
#    pre += "</div> <!-- container -->\n"
#    pre += insert_javascript("https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js")
#    pre += insert_javascript("https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.9/jquery-ui.min.js")
#    pre += js unless js.blank?
#    pre += "</body>\n</html>"
  rescue => detail
    puts "Exception in wrap_with_layout"
    puts detail.message
  end
  
  def multiview where=""
    "<div class=\"multiview\">Render as " +
    [
      #"<a href=\"#{where}\">Lecture Notes</a>",
      #"<a href=\"#{where}?as=outline\">Outline</a>",
      "<a href=\"#{linked_path(html_path(slideshow_path(where)))}\">Slideshow</a>",
      "<a href=\"#{linked_path(html_path(accordion_path(where)))}\">Accordion</a>"
    ].join(" | ") + 
    "</div>"
  end
  
  def build_title path
    path = filter_path path
    clean = Pathname.new(path).cleanpath.to_s
    last = clean.to_s.split('/').last
    
    if last.blank? or last == "."
      page_title = @site_name
      title = @site_name
    else
      page_title = titleize(last).to_s
      title = page_title.to_s + " | " + @site_name.to_s
    end
    
    return title.to_s
  end
  
  def replace_image_urls content, url
    return str.gsub(/((!+)((\(+)([A-Za-z0-9\-_]*)(\)+))([A-Za-z0-9.\/\-_%]*)(!+))|((!+)([A-Za-z0-9.\/\-_%]*)(!+))/) do |s| 
      if s.include?('http://')
        # External image. Just return the match.
        s
      elsif s.include?(')')
        # Image has a class declared.
        s.gsub!(')',')' + url)
      else
        s.sub!('!','!' + url)
      end
    end
  end

  def wrap_tag_contents tag, str
    level2 = str.to_s.split(tag)
    result = []
    level2.each_index do |i|
      if i>0
        str = level2[i]
        if tag == "h2."
          str = wrap_tag_contents "h3.", str
        elsif tag == "h3."
          str = wrap_tag_contents "h4.", str
        end
        result += [tag + str.sub("\n","\n\n<div class=\"level\">") + "</div>\n"]
      end
    end
    return level2[0] + result.join
  end
  
  def wrap_accordion str=""
    return wrap_slides str, true
  end
  
  # Slides are not recursive. Then are arranged linearly, one after another.
  def wrap_slides str="", after_tag=false
    return "" if str.blank?
    # Split by all headers first.
    headers = /h1\.\s|h2\.\s|h3\.\s|h4\.\s/
    slides = str.to_s.split(headers)
    
    first = slides.delete_at(0)
    
    if after_tag
      slides = slides.collect { |slide| 
        lines = slide.split("\n")
        title = lines.delete_at(0)
        slide = lines.join("\n")
        "h2. #{title}\n\n<div class=\"slide\">\n#{slide}\n\n</div>\n\n"
      }
    else
      slides = slides.collect { |slide| "<div class=\"slide\">\n\nh2. #{slide}</div>\n"}
    end
    
    return first + slides.join
  end
  
  
  # Path helpers.........................................................
  
  def filter_path path
    if path.include?("index.")
      # Remove the index.
      index_file = File.basename(path)
      path.sub!(index_file, "")
    elsif not File.directory?(path)
      # Remove the file extension.
      ext = File.extname(path)
      path.sub!(ext,"")
    end
    return path
  end
  
  def html_path path=""
    ext = File.extname(path)
    return path.sub(ext, ".html")
  end
  
  def slideshow_path path=""
    ext = File.extname(path)
    return path if ext.blank?
    return path.sub(ext, "-slideshow"+ext)
  end
  
  def accordion_path path=""
    ext = File.extname(path)
    return path if ext.blank?
    return path.sub(ext, "-accordion"+ext)
  end
  
  def linked_path path=""
    return Pathname.new( File.join( @link_root.to_s, path.to_s ).to_s ).cleanpath.to_s
  end
  
  def path_to file
    if file.is_a?(String)
      if File.directory?(file)
        return file
      else
        return file.to_s.gsub(File.basename(file),"")
      end
    elsif file.is_a?(File)
      if File.directory?(file.path)
        return file.path
      else
        return file.path.gsub(File.basename(file.path),"")
      end
    end
  end
  
  def remove_trailing_slash path=""
    return "" if path.blank?
    
    if path[-1].chr == "/"
      return path.reverse.sub("/","").reverse
    end
    
    return path
  end
  
  def remove_leading_slash path=""
    return "" if path.blank?
    
    if path[0].chr == "/"
      return path.sub("/","")
    end
    
    return path
  end
  
  def add_leading_slash path=""
    return "" if path.blank?
    
    if path[0].chr != "/"
      return "/" + path
    end
    
    return path
  end
  
  def titleize str=""
    str.to_s.gsub( File.extname(str.to_s), "" ).gsub("-"," ").gsub("/","").titlecase
  end

  def link_to text, url
    "<a href=\"#{url}\">#{text}</a>"
  end
  
  def render_breadcrumb path
    path = path.dup
    
    add_html_to_end = false
    if path.include?("index.")
      # Remove the index.
      index_file = File.basename(path)
      path.sub!(index_file, "")
    elsif not File.directory?(path)
      # Remove the file extension, but make sure the breadcrumb
      # adds .html to the file name when it becomes a link later.
      ext = File.extname(path)
      path.sub!(ext,"")
      add_html_to_end = true
    end
    
    path = Pathname.new(path).cleanpath.to_s
    
    crumbs = []
    if use_strict_index_links
      crumbs += [link_to( "Home", linked_path("/index.html") )]
    else
      crumbs += [link_to( "Home", linked_path("/") )]
    end
    url = "/"
    
    paths = path.to_s.split('/')
    paths.delete_if {|p| p == "."}
    
    paths.each do |folder|
      this_url = ""
      
      if add_html_to_end and paths.last == folder
        url += folder + ".html"
        this_url = url
      else
        url += folder + "/"
        
        if use_strict_index_links
          this_url = url + "index.html"
        else
          this_url = url
        end
      end
      
      crumbs += [link_to( titleize(folder), linked_path(this_url) )]
    end
    crumbs.reverse!
    return "&nbsp;&middot; " + crumbs[1..(crumbs.length-1)].join(" &middot; ")
  end

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

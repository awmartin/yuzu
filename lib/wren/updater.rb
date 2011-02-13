require 'pathname'
require 'stringio'
require 'haml'
require 'RedCloth'
require 'suppressor'

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
    @menu_contents = load_partial "_menu.haml", {:path => @local_relative_path}
    @footer_contents = load_partial "_footer.haml"
    puts "Done with partials."
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
  
  # @param extensions Array of Strings: Extensions for the files to upload raw, without processing of any kind.
  def upload_all_files_of_types current_location=".", extensions=[]
    
    Dir.foreach(current_location) do |filename|
      # Exclude ".", "..", hidden folders, and partials.
      
      if filename[0].chr != "." and filename[0].chr != "_"
        file_path = concat_path( current_location, filename )
        
        if File::directory?(file_path) and not folder_blacklist.include? file_path
          
          # Update files with these extensions recursively.
          upload_all_files_of_types file_path, extensions
          
        elsif file_path.includes_one_of? extensions
          
          puts "Opening #{file_path} for upload."
          file = File.open(file_path, "r")
          upload_file file_path, file
          
        end
      end
    end
    
  end
  
  def upload_all_images current_location="."
    upload_all_files_of_types current_location, image_extensions
  end
  
  def upload_all_assets current_location="."
    upload_all_files_of_types current_location, asset_extensions
  end
  
  def upload_all_resources current_location="."
    upload_all_files_of_types current_location, resource_extensions
  end
  
  # One point of exit for the process to upload the file to the proper location.
  # The Uploader object keeps track of the destination and the service (s3, filesystem, etc.).
  def upload_file local_path="", contents=""
    return if local_path.blank? or contents.blank?
    
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
    
    if File::directory? local_path
      
      file, local_path = render_index( local_path )
      
    elsif processable? local_path
      
      puts "Opening: #{local_path}"
      file = File.open(local_path, 'r')
      
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
    else
      # Hand the file over to be processed, which includes conversion to HTML.
      contents = process_file( file )
      file.close
    end
    
    post_process local_path, wrap_with_layout(contents), update_all
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
      str = render_list_index file_path
      index = StringIO.new(str)
      index_path = File.join( folder_path, "index.html")
    end
    
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
    
    lines = file.readlines
    lines.each do |line|
      if past_first_header and not line.strip.blank? and line.strip[0].chr != "!" and line.match(headers).blank?
        if File.extname( file.path ).include?(".text")
          paragraph = render_textile line, file.path
        else
          paragraph = line
        end
        break
      end
      
      if not line.match(headers).blank? and not past_first_header
        past_first_header = true
      end
    end
    
    return paragraph
  end
  
  # Give it a path, and it returns a string consisting of a list of links and first paragraphs.
  # TODO Allow for the contents to be styled, adding css classes to the list items.
  # TODO Add functionality to include images. (Grab the first image tag?)
  def insert_catalog path="", options={}
    return "" if path.blank?
    return "" if not File.directory? path
    default_options = {
      :ordered => false,
      :class => ""
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
    
    text = ""
    
    entries = Dir[File.join(path,"*")] # Just lists filenames and directory names
    #entries.delete_if {|e| e[0].chr == "."}
    sorted = entries.collect { |f|
      [test(?M, f), f]
    }.sort.collect { |f| f[1] }

    
    text += "<#{tag}#{css_class}>\n"
    text += sorted.collect { |entry_path|
      name = titleize( entry_path.split("/").last )
      
      #entry_path = File.join( path, entry )
      
      if File.directory?( entry_path )
        # Locate the index.
        index, index_path = open_index entry_path
        if index.blank?
          paragraph = ""
        else
          paragraph = extract_first_paragraph index
          index.close
        end
      else
        if processable? entry_path
          file = File.open( entry_path, "r" )
          paragraph = extract_first_paragraph file
          file.close
        end
      end
      
      # Build the URL for the link.
      link_url = entry_path.dup
      # Add a slash to the ends of folder urls. Makes java applets work.
      link_url += "/" if File.directory?( entry_path ) and entry_path[-1].chr != "/"
      
      if File.directory?( link_url ) and use_strict_index_links
        link_url = File.join( link_url, "index.html" )
      end
      
      str = "<li><a href=\"#{linked_path(html_path(link_url))}\">#{name}</a>"
      str += "<br />#{paragraph}" unless paragraph.blank?
      str += "</li>\n"
      str
    }.join
    text += "</#{tag}>\n"
    return text
  end
  
  # Index pages are generated as an unordered list of links to all the folders
  # and files inside a parent folder. This happens when there is no index.text
  # or index.haml file found.
  def render_list_index path
    return "" if not File::directory?( path )
    puts "Building an index page for path #{path}..."
    
    @page_title = build_title path
    @html_head = load_partial "_head.haml"
    @menu_contents = load_partial "_menu.haml", {:path => path}
    
    text = "<h1>#{@page_title}</h1>"
    text += insert_catalog path
    
    return text
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
    @menu_contents = load_partial "_menu.haml", {:path => file.path}
    
    # Handle files.
    if file_ext.includes_one_of?( image_extensions + asset_extensions )
      # Images and other binary files... Do nothing.
      
    elsif file_ext.includes_one_of? ["txt","pde","rb"]
      puts "Plain text or code found."
      
      return contents
    else
      
      if file_ext.include? 'text'
        # Catches ".text" and ".textile" extensions.
        puts "Textile file found."
        return render_textile( contents, file.path )
        
      elsif file_ext.include? 'html'
        puts "HTML file found."
        return contents
        
      elsif file_ext.include? 'haml'
        puts "HAML file found."
        return render_haml( contents )
        
      else
        puts "Unprocessable file found."
        return contents
        
      end
    
    end
    
  rescue => detail
    puts "EXCEPTION in process_file..."
    puts detail.message
    return ""
  end
  
  # Loads the HAML partials for the layout. Especially _head.haml, _header.haml, 
  # _footer.haml, _menu.haml.
  def load_partial local_path="", data={}
    return "" if local_path.blank?
    
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
      })
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
  def render_textile str="", local_path=""
    return "" if str.blank?
    path_to_file = Pathname.new( path_to(local_path) ).cleanpath.to_s
    
    puts "Rendering textile for #{local_path}..."
    
    puts "Inserting children..."
    # Replace all the keywords with their values first.
    str.gsub!(/INSERTCONTENTS\(([A-Za-z0-9\.\-\/_]*)\)/) do |s|
      path_of_file_to_insert = remove_leading_slash s.gsub("INSERTCONTENTS(","").gsub(")","")
      puts "Inserting contents of #{path_of_file_to_insert}"
      insert_file(path_of_file_to_insert).gsub("MULTIVIEW","")
    end
    
    puts "Inserting catalogs..."
    str.gsub!(/INSERTCATALOG\(([A-Za-z0-9\.\-\/_]*)\)/) do |s|
      path_of_folder_to_insert = remove_leading_slash s.gsub("INSERTCATALOG(","").gsub(")","")
      puts "Inserting catalog of #{path_of_folder_to_insert}"
      insert_catalog(path_of_folder_to_insert, {:ordered => true, :class => "blocks"})
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
    
    return RedCloth.new(str).to_html
  rescue => exception
    puts "EXCEPTION in Uploader#render_textile"
    puts exception.message
    return ""
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
  def wrap_with_layout contents="", js=""
    pre = "<!DOCTYPE html>\n<html lang='en-US' xml:lang='en-US' xmlns='http://www.w3.org/1999/xhtml'>\n"
    pre += @html_head.to_s
    pre += "<body>\n"
    pre += "<div class='container'>\n"
    pre += "<div class='header'>#{@header_contents}#{@menu_contents}</div> <!-- header -->\n"
    pre += "<div class='content'>#{contents}</div> <!-- content -->\n"
    pre += "<div class='footer'>#{@footer_contents}</div> <!-- footer -->\n"
    pre += "</div> <!-- container -->\n"
    pre += insert_javascript("https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js")
    pre += insert_javascript("https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.9/jquery-ui.min.js")
    pre += js unless js.blank?
    pre += "</body>\n</html>"
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
    return Pathname.new( File.join( @link_root, path ) ).cleanpath.to_s
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

    return crumbs.join(" &gt; ")
  end

  def is_outline?
    false
  end

  def is_slideshow?
    false
  end
  
  def done
    @uploader.close
    @suppressor.close
  end

end

require 'pathname'

require "content_handlers"
require 'renderers/layout'
require 'renderers/textile_renderer'
require 'renderers/haml_renderer'


def preprocess_keywords str, local_path, config, pageinfo, galleries
  metadata = {}

  path_to_file = Pathname.new( path_to(local_path) ).cleanpath.to_s
  
  # Handle INSERTCONTENTS keywords first...
  str = insert_contents(str)
  
  metadata[:post_title], str = extract_title(str)
  metadata[:categories], str = extract_categories(str)
  
  images, str = extract_images(str)
  
  str = insert_gallery(str, images, galleries)

  template, str = extract_template(str)
  
  sidebar_contents, str = extract_sidebar_contents(str)
  
  str = insert_catalogs(str, local_path, config, pageinfo)
  
  str = insert_currentpath(str, linked_path(pageinfo, path_to_file))
  
  str = insert_linkroot(str, remove_trailing_slash(pageinfo.link_root))
  
  #str = insert_multiview(str, local_path)

  # Image url replacement. Not needed on an Apache server.
  #user_id = ENV['DROPBOX_ON_RAILS_USER_ID']
  #full_url = "http://dl.dropbox.com/u/#{user_id}#{APP_@config[:site_folder]}".gsub('/Public','')
  #str = replace_image_urls str, full_url
  
  return str, template, metadata
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

def insert_contents str
  str.gsub(/INSERTCONTENTS\(([A-Za-z0-9\.\-\/_]*)\)/) do |s|
    path_of_file_to_insert = remove_leading_slash s.gsub("INSERTCONTENTS(","").gsub(")","")
    puts "Inserting contents of #{path_of_file_to_insert}"
    insert_file(path_of_file_to_insert).gsub("MULTIVIEW","")
  end
end

def extract_title str
  # Extract the title if any.
  post_title = ""
  tr = str.gsub(/TITLE\(([A-Za-z0-9\,\.\-\/_\s\:\|]*)\)/) do |s|
    post_title = s.gsub("TITLE(","").gsub(")","")
    ""
  end
  return post_title, tr
end

def extract_images str
  # Look for images.
  images = []
  tr = str.gsub(/IMAGES\(([A-Za-z0-9\,\.\-\/_]*)\)/) do |s|
    images_str = s.gsub("IMAGES(","").gsub(")","")
    images += images_str.split(",")
    ""
  end
  return images, tr
end

def insert_gallery str, images, galleries
  # Look for galleries and insert images.
  tr = str.gsub("INSERTGALLERY") do |s|
    if galleries
      url = images.first
      url.gsub!(".","-large.")
      "<div class=\"slideshow\">\n<div class=\"slide\">\n!#{url}!\n</div>\n</div>"
    else
      ""
    end
  end
  return tr
end

def extract_template str
  # Look for template specification.
  template = "_generic.haml"
  tr = str.gsub(/TEMPLATE\(([A-Za-z0-9\.\-\/_]*)\)/) do |s|
    template = s.gsub("TEMPLATE(","").gsub(")","")
    ""
  end
  return template, tr
end

def extract_sidebar_contents str
  # Find any sidebar contents.
  sidebar_contents = ""
  tr = str.gsub(/SIDEBARCONTENTS\(\"[A-Za-z0-9\%\n\.\,\'\"\/\-_]*\"\)/) do |s|
    sidebar_contents = s.gsub("SIDEBARCONTENTS(\"","").gsub("\")","")
    ""
  end
  return sidebar_contents, tr
end

def extract_categories str
  # Find any sidebar contents.
  categories = []
  tr = str.gsub(/CATEGORIES\(\"[A-Za-z0-9\s\.\,\'\"\/\-_]*\"\)/) do |s|
    categories = s.gsub("CATEGORIES(\"","").gsub("\")","").split(",")
    categories = categories.collect {|str| str.strip}
    ""
  end
  
  if categories.blank?
    categories = ["Uncategorized"] # TODO: config var for default category
  end
  
  return categories, tr
end


def get_recent_blog_posts blog_dir
  puts "get_recent_blog_posts"
  
  blog_dir = @config.blog_dir
  
  if File.exists?(blog_dir)
    return get_catalog_contents(blog_dir).collect {|r| r.gsub(".text",".html")}
  else
    return []
  end
  
rescue => exception
  puts ">>>> Exception in get_recent_blog_posts"
  puts exception.message
  puts exception.backtrace
  return []
end

def get_catalog_contents path="", options={}
  puts "get_catalog_contents"
  
  default_options = {
    :ordered => false,
    :class => "",
    :count => 12,
    :start => 0,
    :sort_by => :name,
    :block_template => "_block.haml",
    :blocks_per_row => 1,
    :exclude_paths => [],
    :category_filter => "" # TODO
  }
  options = default_options.dup.update(options)
  
  entries = Dir[File.join(path,"*")] # Just lists filenames and directory names
  
  # Traverse one folder deep to gather all files.
  entries.each do |entry|
    subpath = entry
    if File.directory?(subpath)
      subpath_entries = Dir[File.join(subpath, "*")]
      entries += subpath_entries
    end
  end
  
  puts "#{entries.length} entries found."
  
  # Sort all the entries.
  if options[:sort_by] == :name
    sorted = entries.sort{ |a,b| File.basename(b) <=> File.basename(a) }
    
  elsif options[:sort_by] == :modified
    sorted = entries.collect { |f|
      [test(?M, f), f]
    }.sort.collect { |f| f[1] }
    
  end
  
  # Attempt to exclude troublemakers... Do this before the list slicing...
  sorted = sorted.reject {|p| p.include?("index.") or File.directory?(p)}
  #sorted.delete_if {|e| e[0].chr == "."}
  #and not options[:exclude].include?(File.basename(entry_path))
  
  count = options[:count]
  if count > 0
    sorted = sorted[options[:start]...(count+options[:start])]
  end
  return sorted
end


# Give it a path, and it returns a string consisting of a list of links and first paragraphs.
# TODO Allow for the contents to be styled, adding css classes to the list items.
# TODO Add functionality to include images. (Grab the first image tag?)
def insert_catalog path="", options={}, config=nil, pageinfo=nil
  return "" if path.blank?
  return "" if not File.directory? path
  if pageinfo.nil?
    puts "ASSERTION ERROR: insert_catalog: pageinfo cannot be nil!"
    return ""
  end
  
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
  
  sorted = get_catalog_contents(path, options)
  
  puts "sorted has #{sorted.length} entries"
  
  text = ""
  
  sorted.each_index do |i|
    puts i
    
    actual_index = i + options[:start]
    
    if actual_index >= options[:start] # TODO: ?????
      entry_path = sorted[i]
      
      puts "Processing catalog item: #{entry_path}"
    
      if i % options[:blocks_per_row] == 0
        text += "<hr />\n"
      end
      
      post_title = extract_title_from_filename(File.join(path, entry_path))
      post_date = extract_date_from_filename(entry_path)
      
      if File.directory?(entry_path)
        # Locate the index.
        index, index_path = open_index(entry_path)
        if index.blank?
          paragraph = ""
          image_path = ""
        else
          file_type = get_file_type(config, index)
          paragraph = extract_first_paragraph(index, file_type)
          image_path = extract_first_image(index)
          contents = paragraph
          index.close
        end
      else
        if config.processable?(entry_path)
          file = File.open( entry_path, "r" )
          file.rewind
          lines = file.readlines
          file_type = get_file_type config, file
          
          paragraph = extract_first_paragraph(file, file_type)
          image_path = extract_first_image(file)
          
          if file_type == :textile
            contents, template, metadata = TextileRenderer.new(config, pageinfo, false, true).render(lines.join("\n"), file.path)
          elsif file_type == :haml
            contents, template, metadata = HamlRenderer.new(config, pageinfo, false).render(lines.join("\n"), file.path)
          end
          
          file.close
        end
      end
      
      linkroot = remove_trailing_slash(pageinfo.link_root)
      
      image_path.gsub!("LINKROOT", linkroot)
      image_path_small = image_path.gsub(".","-small.")
      image_path_medium = image_path.gsub(".","-medium.")
      image_path_large = image_path.gsub(".","-large.")
      
      # Build the URL for the link.
      link_url = File.join(pageinfo.link_root, html_path(entry_path))
      
      # Add a slash to the ends of folder urls. Makes java applets work.
      link_url += "/" if File.directory?(entry_path) and entry_path[-1].chr != "/"
      
      if File.directory?( link_url ) and config.use_strict_index_links
        link_url = File.join( link_url, "index.html" )
      end
      
      lyt = LayoutHandler.new(config, pageinfo)
      opts = {:post_title => post_title,
              :post_date => post_date,
              :contents => contents,
              :first_paragraph => paragraph,
              :image_path => image_path,
              :image_path_small => image_path_small,
              :image_path_medium => image_path_medium,
              :image_path_large => image_path_large,
              :klass => (((actual_index % options[:blocks_per_row]) == (options[:blocks_per_row] - 1)) ? "last" : ""),
              :link_url => link_url,
              :link_root => pageinfo.link_root,
              :categories => metadata[:categories]}
      str = lyt.load_template(options[:block_template], opts)
      
      # Remove space-indentations.
      str = str.gsub(/\n\s*/,"")
      
      text += str + "\n"
    end
  end
  
  return text
  
rescue => detail
  puts "Exception in insert_catalog..."
  puts detail.message
  puts detail.backtrace
  return "Error in insert_catalog..."
end

# @param contents String - Single string containing the contents of the file to search through.
# @returns folder path(String), start position(integer), count of files(integer), 
#   blocks per row(integer), block template(String)
def extract_first_catalog contents
  matches = contents.match(/INSERTCATALOG\(([A-Za-z0-9\,\.\-\/_]*)\)/)
  
  if not matches.nil?
    arg_str = matches[0].to_s.gsub("INSERTCATALOG(","").gsub(")","")
    args = arg_str.split(",")
    
    path_of_folder_to_insert = remove_leading_slash(args[0].to_s)
    
    if args.length > 1
      if args[1] == "PAGINATE"
        start = -1 # TODO: Magic number!
      else
        start = 0
      end
    else
      start = 0
    end
    
    count = args.length > 2 ? args[2].to_i : 10
    blocks_per_row = args.length > 3 ? args[3].to_i : 1
    block_template = args.length > 4 ? args[4].to_s : "_block.haml"
    
    return path_of_folder_to_insert, start, count, blocks_per_row, block_template
  else
    return nil, nil, nil, nil, nil
  end
end

def insert_catalogs str, local_path, config, pageinfo
  puts "Inserting catalogs..."
  if pageinfo.nil?
    puts "ASSERTION ERROR: insert_catalogs: pageinfo cannot be nil!"
    return ""
  end
  
  tr = str.gsub(/INSERTCATALOG\(([A-Za-z0-9\,\.\-\/_]*)\)/) do |s|
    arg_str = s.gsub("INSERTCATALOG(","").gsub(")","")
    args = arg_str.split(",")
    
    # Extract the arguments.
    path_of_folder_to_insert = remove_leading_slash(args[0].to_s)
    start = args.length > 1 ? args[1].to_i : 0
    count = args.length > 2 ? args[2].to_i : 10
    blocks_per_row = args.length > 3 ? args[3].to_i : 1
    block_template = args.length > 4 ? args[4].to_s : "_block.haml"
    
    puts "Inserting catalog of #{path_of_folder_to_insert} with #{count} items (zero = all)."
    opts = {:ordered => true, 
            :class => "blocks", 
            :count => count,
            :start => start,
            :blocks_per_row => blocks_per_row,
            :block_template => block_template,
            :exclude => [File.basename(local_path)]}
    
    insert_catalog(path_of_folder_to_insert, opts, config, pageinfo)
  end
  return tr
end

def insert_currentpath str, current_relative_path
  # This depends on the location in the recursion. It can't be done like this really.

  puts "Replacing CURRENTPATH with #{current_relative_path}"
  tr = str.gsub("CURRENTPATH", current_relative_path)
  return tr
end

def insert_linkroot str, linkroot
  puts "Replacing LINKROOT with #{linkroot}"
  tr = str.gsub("LINKROOT", linkroot)
  return tr
end




def render_breadcrumb path, config, pageinfo
  path = path.dup
  use_strict_index_links = config.use_strict_index_links
  
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
    crumbs += [link_to( "Home", linked_path(pageinfo, "/index.html") )]
  else
    crumbs += [link_to( "Home", linked_path(pageinfo, "/") )]
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
    
    str = titleize(folder)
    crumbs += [link_to( str, linked_path(pageinfo, this_url) )]
  end
  
  crumbs.reverse!
  
  return "&nbsp;&middot; " + crumbs[1..(crumbs.length-1)].join(" &middot; ")
rescue => exception
  puts "Exception in breadcrumb renderer..."
  puts exception.message
  return ""
end

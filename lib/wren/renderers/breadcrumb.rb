
def render_breadcrumb file_cache, blog_categories=nil
  path = file_cache.relative_path
  config = file_cache.config

  omit_current_page = config.breadcrumb_omit_current_page rescue false
  file_path = path.dup
  use_strict_index_links = config.use_strict_index_links
  
  add_html_to_end = false
  if file_cache.relative_path.include?("index.")
    file_path = file_cache.relative_path.gsub(file_cache.basename, "")
  elsif file_cache.file?
    file_path = file_cache.relative_path.gsub(file_cache.extension, "")
  end
  
  # If blog_categories is not blank, insert /category/ to the path.
  # Indices are not categorizable.
  # Must have a blog_dir specified in the config.
  if not blog_categories.blank? and not path.include?('index') and !config.blog_dir.blank?
    file_path.sub!(config.blog_dir, "#{config.blog_dir}/#{blog_categories.first.downcase}")
  end
  
  # Clean the path.
  file_path = Pathname.new(file_path).cleanpath.to_s
  
  crumbs = []
  if use_strict_index_links
    crumbs += [link_to( "Home", File.join(config.link_root, "/index.html") )]
  else
    crumbs += [link_to( "Home", File.join(config.link_root, "/") )]
  end
  url = "/"
  
  paths = file_path.to_s.split('/')
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
    crumbs += [link_to( str, File.join(config.link_root, this_url) )]
  end
  
  crumbs.reverse!
  
  sep = config.breadcrumb_separator
  
  if crumbs.length == 1
    return crumbs.first
  else
    if omit_current_page
      return "&nbsp;#{sep} " + crumbs[1..(crumbs.length-1)].join(" #{sep} ")
    else
      return crumbs.join(" #{sep} ")
    end
  end
end

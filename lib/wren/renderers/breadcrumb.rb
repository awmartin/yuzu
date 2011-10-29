require 'content_handlers'

# TODO: Build a better breadcrumb. This is *much* easier of the FileCache objects
# actually know their immediate parent. For now, this url splitting is working,
# but multiple categories aren't working.

def render_breadcrumb file_cache, blog_categories=nil
  path = file_cache.relative_path
  config = file_cache.config

  omit_current_page = config.breadcrumb_omit_current_page rescue false
  file_path = path.dup
  use_strict_index_links = config.use_strict_index_links
  
  add_html_to_end = false
  if file_cache.relative_path.include?("index.")
    file_path = File.dirname(file_cache.relative_path)
  elsif file_cache.file?
    file_path = file_cache.relative_path.gsub(file_cache.extension, "")
  end
  
  # Date folder structure match. We want to remove the date from the folder
  # structure.
  m = file_path.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}\//)
  if not m.nil?
    file_path.sub!(m.to_s, "")
  end
  
  # Also remove YYYY-MM/DD-title-here.md
  m = file_path.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}\-/)
  if not m.nil?
    file_path.sub!(m.to_s, "")
  end
  
  # If blog_categories is not blank, insert /category/ to the path.
  # Indices are not categorizable.
  # Must have a blog_dir specified in the config.
  if not blog_categories.blank? and not path.include?('index') and !config.blog_dir.blank?
    file_path.sub!(config.blog_dir, "#{config.blog_dir}/#{blog_categories.first.downcase.dasherize}")
  end
  
  # Start the list of crumbs. Add "Home" first.
  crumbs = []
  if use_strict_index_links
    crumbs += [link_to( "Home", File.join(config.link_root, "/index.html") )]
  else
    crumbs += [link_to( "Home", File.join(config.link_root, "/") )]
  end
  
  # Keep track of the url throughout the loop. Tack on a new path each loop.
  paths = file_path.to_s.split('/')
  url = "/"
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

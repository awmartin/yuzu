require 'content_handlers'
require 'renderers/gallery'


# Simple helper for grabbing the contents of a text file.
# Used for the direct insertion of content with INSERTCONTENTS(...)
# This defaults to a path relative to the root of the file system,
# which might not make sense...
def insert_file local_path
  if File.exists?(local_path)
    file = File.open(local_path, "r")
    contents = file.readlines.join
    file.close
    return contents
  else
    return ""
  end
rescue
  return ""
end

# Raw contents insert. Does no intermediate representation or format checking.
def insert_contents str, site_cache
  str.gsub(/INSERTCONTENTS\(([\w\s\.\-\/_]*)\)/) do |s|
    path_of_file_to_insert = s.gsub("INSERTCONTENTS(","").gsub(")","")
    
    begin
      site_cache.get(path_of_file_to_insert).raw_contents
    rescue => detail
      insert_file(path_of_file_to_insert)
    end
  end
end

def extract_extension str
  file_extension = ".html"
  tr = str.gsub(/EXTENSION\(\.([\w\.]*)\)/) do |s|
    file_extension = s.gsub("EXTENSION(","").gsub(")","")
    ""
  end
  return file_extension, tr
end

def extract_title str, file_type, config
  # Extract the title if any.
  
  post_title = ""
  
  if file_type == :markdown
    tr = str.gsub(/^#\s+.*\n/) do |s|
      post_title = s.gsub("#","").strip
      if @config.remove_h1_tags
        ""
      else
        s
      end
    end
  end
  
  if post_title.blank?
    tr = str.gsub(/TITLE\(([\w\s\,\.\-\/\:\|]*)\)/) do |s|
      post_title = s.gsub("TITLE(", "").gsub(")", "").strip
      ""
    end
  end
  
  return post_title, tr
end

def extract_date(str)
  post_date = ""
  tr = str.gsub(/DATE\(([A-Za-z0-9\,\.\-\/_\s\:\|]*)\)/) do |s|
    post_date = s.gsub("DATE(", "").gsub(")", "").strip
    ""
  end
  return post_date, tr
end

def extract_description_meta(str)
  # Extract the text for the description meta tag, if any.
  description = ""
  tr = str.gsub(/DESCRIPTION\(([\w\,\.\-\/\s\:\|\n]*)\)/) do |s|
    description = s.gsub("DESCRIPTION(", "").gsub(")", "").strip
    ""
  end
  return description, tr
end

def extract_images(str)
  # Look for images.
  images = []
  tr = str.gsub(/IMAGES\(([\w\,\.\-\/$\s]*)\)/) do |s|
    images_str = s.gsub("IMAGES(","").gsub(")","")
    images += images_str.split(",").collect {|im| im.strip}
    ""
  end
  return images, tr
end

def insert_thumbnails(str) #, link_root, current_path
  # Look for galleries and insert images.
  # TODO: Add javascript integration

  tr = str.gsub(/THUMBNAILS\(([\w\,\.\-\/$\s]*)\)/) do |s|
    images_str = s.gsub("THUMBNAILS(","").gsub(")","")
    images = images_str.split(",").collect {|im| im.strip}
    group_name = images[0]
    images = images[1..images.length]
    #images = images.collect {|img| img.gsub("linkroot", link_root)}
    #images = images.collect {|img| img.gsub("linkroot", link_root)}
    thumbnail_gallery(images, group_name)
  end
  return tr
end

def extract_template(str)
  # Look for template specification.
  template = "generic.haml"
  tr = str.gsub(/TEMPLATE\(([A-Za-z0-9\.\-\/_]*)\)/) do |s|
    template = s.gsub("TEMPLATE(","").gsub(")","")
    ""
  end
  return template, tr
end

def extract_sidebar_contents str, config
  # Find any sidebar contents.
  sidebar_contents = ""
  tr = str.gsub(/SIDEBAR\{([\w\s\n\*\#\%\.\,\"\'\/\-\[\]\:\)\(<>_=]*)\}/) do |s|
    sidebar_contents = s.gsub("SIDEBAR{", "").gsub("}", "")
    ""
  end
  return sidebar_contents.gsub("LINKROOT", config.link_root), tr
end

def extract_categories str
  # Find any sidebar contents.
  categories = []
  tr = str.gsub(/CATEGORIES\([\w\s\.\,\'\"\/\-]*\)/) do |s|
    categories = s.gsub("CATEGORIES(","").gsub(")","").split(",")
    categories = categories.collect {|str| str.strip.downcase}
    ""
  end
  
  if categories.blank?
    categories = ["uncategorized"] # TODO: config var for default category
  end
  
  return categories, tr
end

def get_recent_blog_posts blog_dir
  
  blog_dir = @config.blog_dir
  
  if File.exists?(blog_dir)
    return get_catalog_contents(blog_dir).collect {|r| r.gsub(".text",".html")}
  else
    return []
  end
  
end

def insert_currentpath str, current_relative_path
  # This depends on the location in the recursion. It can't be done like this really.
  tr = str.gsub("CURRENTPATH", current_relative_path)
  return tr
end

def insert_linkroot str, linkroot
  tr = str.gsub("LINKROOT", linkroot.to_s)
  return tr
end

def insert_blog_dir str, blog_dir
  tr = str.gsub("BLOGDIR", blog_dir.to_s)
  return tr
end

def should_render_slideshow? str
  tr = str.include?("+SLIDESHOW")
  str.gsub!("+SLIDESHOW", "")
  return tr, str
end


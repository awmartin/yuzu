require "content_handlers"
require 'renderers/gallery'



# Simple helper for grabbing the contents of a text file.
# Used for the direct insertion of content with INSERTCONTENTS(...)
# This defaults to a path relative to the root of the file system,
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

def extract_extension str
  file_extension = ".html"
  tr = str.gsub(/EXTENSION\(\.([A-Za-z0-9\.]*)\)/) do |s|
    file_extension = s.gsub("EXTENSION(","").gsub(")","")
    ""
  end
  return file_extension, tr
end

def extract_title str
  # Extract the title if any.
  post_title = ""
  tr = str.gsub(/TITLE\(([A-Za-z0-9\,\.\-\/_\s\:\|]*)\)/) do |s|
    post_title = s.gsub("TITLE(", "").gsub(")", "").strip
    ""
  end
  return post_title, tr
end

def extract_date str
  # Extract the title if any.
  post_date = ""
  tr = str.gsub(/DATE\(([A-Za-z0-9\,\.\-\/_\s\:\|]*)\)/) do |s|
    post_date = s.gsub("DATE(", "").gsub(")", "").strip
    ""
  end
  return post_date, tr
end

def extract_description_meta str
  # Extract the text for the description meta tag, if any.
  description = ""
  tr = str.gsub(/DESCRIPTION\(([\w\,\.\-\/\s\:\|\n]*)\)/) do |s|
    description = s.gsub("DESCRIPTION(", "").gsub(")", "").strip
    ""
  end
  return description, tr
end

def extract_images str, link_root
  # Look for images.
  images = []
  tr = str.gsub(/IMAGES\(([\w\,\.\-\/$\s]*)\)/) do |s|
    images_str = s.gsub("IMAGES(","").gsub(")","")
    images += images_str.split(",").collect {|im| im.strip}
    ""
  end
  images = images.collect {|img| img.gsub("LINKROOT", link_root)}
  return images, tr
end

def show_gallery? str
  show = false
  tr = str.gsub("INSERTGALLERY") do |s|
    show = true
    ""
  end
  return show, tr
end

def insert_gallery str, images, galleries, pageinfo
  # Look for galleries and insert images.
  # TODO: Add javascript integration
  
  tr = str.gsub("INSERTGALLERY") do |s|
    if galleries
      render_gallery(images, pageinfo)
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

def extract_sidebar_contents str, config
  # Find any sidebar contents.
  sidebar_contents = ""
  tr = str.gsub(/SIDEBAR\{([\w\s\%\n\.\,\'\/\-\[\]\:\)\(_]*)\}/) do |s|
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
  tr = str.gsub("LINKROOT", linkroot)
  return tr
end



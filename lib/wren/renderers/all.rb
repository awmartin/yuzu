require 'maruku'
require 'haml'
require 'RedCloth'

# General rendering method for all supported file types.
def render str, file_type
  if file_type == :asset or file_type == :image
    return nil
  elsif file_type == :plaintext or file_type == :html
    return str
  elsif file_type == :textile
    return RedCloth.new(str).to_html
  elsif file_type == :haml
    return Haml::Engine.new(str, {:format => :html5}).render #(Object.new, {})
  elsif file_type == :markdown
    return Maruku.new(str).to_html
  else
    return str
  end
end

# Look for the INSERT(...) tag and insert the resulting HTML. This will 
# currently only work for partials without any variables or dependencies, 
# or raw files with no tags.
#
# TODO: use the site_cache to insert rendered contents.
def insert_rendered_contents str, config
  str.gsub(/INSERT\(([\w\.\-\/_]*)\)/) do |s|
    path_of_file_to_insert = s.gsub("INSERT(","").gsub(")","")
    puts "Inserting rendered contents of #{path_of_file_to_insert}"
    
    extension = File.extname(path_of_file_to_insert)
    file_type = get_file_type(extension, config)
    raw_contents = insert_file(path_of_file_to_insert).gsub("MULTIVIEW", "")
    
    return render(raw_contents, file_type)
  end
end

# Renders the raw string and adds all INSERT(...) contents as HTML.
def render_with_insertions str, file_type, config
  rendered_contents = render(str, file_type)
  final = insert_rendered_contents(rendered_contents, config)
end

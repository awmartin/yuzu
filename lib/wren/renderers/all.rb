#require 'maruku'
require 'kramdown'
require 'rdiscount'
require 'haml'
require 'RedCloth'

# General rendering method for all supported file types.
def render str, file_type, scope=nil
  if file_type == :asset or file_type == :image
    return nil
    
  elsif file_type == :plaintext or file_type == :html
    return str
    
  elsif file_type == :textile
    return RedCloth.new(str).to_html
    
  elsif file_type == :haml
    if scope.nil?
      scope = Object.new
    end
    return Haml::Engine.new(str, {:format => :html5}).render(scope)
  
  elsif file_type == :markdown
    #rendered = Kramdown::Document.new(str, :parse_block_html => true).to_html
    rendered = Kramdown::Document.new(str).to_html

    #rendered = RDiscount.new(str).to_html
    rendered = rendered.gsub("<p><noscript></p>", "<noscript>").gsub("<p></noscript></p>", "</noscript>")
    return rendered.gsub(/\n\s*<\/code>/, "</code>").gsub(/<code>(?!\s)/, "<code>  ")
  else
    return str
  end
end

# Look for the INSERT(...) tag and insert the resulting HTML. This will 
# currently only work for partials without any variables or dependencies, 
# or raw files with no tags.
#
# TODO: use the site_cache to insert rendered contents of already cached
# files, but not files outside of the site folder. Watch for circular references.
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
# Called after the rendered contents of a file_cache are produced.
def render_with_insertions str, file_type, config
  rendered_contents = render(str, file_type)
  final = insert_rendered_contents(rendered_contents, config)
end

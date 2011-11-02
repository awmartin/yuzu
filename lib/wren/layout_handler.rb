require 'haml'
require 'suppressor'
require 'content_handlers'

class LayoutHandler

  def initialize file_cache
    @file_cache = file_cache
    @config = file_cache.config
  end

  # Loads the HAML partials for the layout. Especially _head.haml, _header.haml, 
  # _footer.haml, _menu.haml.
  def load_partial partial_filename, attr={}
    partial_path = File.join(@config.template_dir, partial_filename)

    partial = File.open(partial_path, 'r')
    partial_contents = partial.readlines.join
    partial.close
    
    opts = {:format => :html5}
    locals = attr.update(@file_cache.attributes)
    
    result = Haml::Engine.new(partial_contents, opts).render(Object.new, locals)
    
    return result
  end
  
  def load_page_partials!
    @html_head = load_partial "_head.haml"
    @header_contents = load_partial "_header.haml"
    @menu_contents = load_partial "_menu.haml"
    
    # Get recent blog posts.
    recents = []
    site_cache = @file_cache.site_cache
    # Look for the blog in the site cache.
    if site_cache.cache.has_key?(@config.blog_dir)
      blog = site_cache.cache[@config.blog_dir]
      recents = blog.catalog_children[0..10]
    end
    
    @footer_contents = load_partial("_footer.haml", {:recents => recents})
  end
  
  def load_template template_filename, options={}
    template_path = File.join @config.template_dir, template_filename
    template = File.open(template_path, 'r')
    template_contents = template.readlines.join
    template.close
    
    attr = (options.update({
      :head => @html_head,
      :contents => @file_cache.rendered_contents, # Triggers the rendering
      :contents_without_first_paragraph => 
        @file_cache.rendered_contents.gsub(@file_cache.attributes[:raw_first_paragraph], ""),
      :contents_with_demoted_headers =>
        @file_cache.rendered_contents_with_demoted_headers,
      :header => @header_contents,
      :footer => @footer_contents,
      :menu => @menu_contents})).update(@file_cache.attributes)
    
    Haml::Engine.new(template_contents, {:format => :html5}).render(Object.new, attr)
  end
  
  # Puts the header and footer in place.
  def wrap_with_layout
    load_page_partials!
    
    return load_template @file_cache.template
  end
end

require 'haml'
require 'suppressor'
require 'content_handlers'
require 'renderers/all'
require 'renderers/keyword_handlers'

class LayoutMethods
  def initialize config, site_cache
    @config = config
    @site_cache = site_cache
  end
  
  def insert_raw_file filename
    if File.exists?(filename)
      
      f = File.open(filename, "r")
      contents = f.readlines.join
      f.close
      return contents
      
    elsif @site_cache.file_exists?(filename)
      
      file_cache = @site_cache.get_file(filename)
      return file_cache.raw_contents
      
    else
      return ""
    end
  end
  
  def get_file_type filename
    extension = File.extname(filename)
    if extension.include? 'text'
      return :textile
    elsif extension.include? 'html'
      return :html
    elsif extension.include? 'haml'
      return :haml
    elsif extension.includes_one_of? ["markdown", "md", "mdown"]
      return :markdown
    else
      return :unknown
    end
  end
  
  def insert_rendered_contents filename
    if File.exists?(filename)
      
      f = File.open(filename, "r")
      contents = f.readlines.join
      f.close
      
      file_type = get_file_type(filename)
      rendered_contents = render(contents, file_type)
      
      tags_replaced = insert_linkroot(insert_blog_dir(rendered_contents, @config.blog_dir), @config.link_root)
      
      return tags_replaced
      
    elsif @site_cache.file_exists?(filename)
      file_cache = @site_cache.get_file(filename)
      
      rendered_contents = render(file_cache.raw_contents, file_cache.file_type)
      
      tags_replaced = insert_linkroot(
                        insert_blog_dir(rendered_contents, @config.blog_dir), 
                        @config.link_root
                        )
      puts tags_replaced
      return tags_replaced
      
    else
      return ""
    end
  end
end


class LayoutHandler

  def initialize file_cache
    @file_cache = file_cache
    @site_cache = file_cache.site_cache
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
    
    result = Haml::Engine.new(partial_contents, opts).render(
                  LayoutMethods.new(@config, @site_cache), 
                  locals
                )
    
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
    
    attr = options.update(
        {
          :head => @html_head,
          :contents => @file_cache.rendered_contents, # Triggers the rendering
          :contents_without_first_paragraph => 
            @file_cache.rendered_contents.gsub(
              @file_cache.attributes[:raw_first_paragraph], ""
              ),
          :contents_with_demoted_headers =>
            @file_cache.rendered_contents_with_demoted_headers,
          :header => @header_contents,
          :footer => @footer_contents,
          :menu => @menu_contents,
          :excerpt_contents => @file_cache.excerpt_contents,
          :excerpt_contents_demoted => @file_cache.excerpt_contents_demoted
        }
      ).update(@file_cache.attributes)
    
    rendered_contents = Haml::Engine.new(
          template_contents, 
          {:format => :html5}
        ).render(LayoutMethods.new(@config, @site_cache), attr)

    #return rendered_contents
    
    # TODO: This is a hack fix, assuming that we're 5 levels indented... Find a way
    # to get around HAML's insistence on indenting the HTML but while preserving the desired
    # indentation inside <pre> tags.
    return rendered_contents.gsub(/\n\s{12}/, "\n") # remove Haml's auto-indentation bullshit
  end
  
  # Puts the header and footer in place.
  def wrap_with_layout
    load_page_partials!
    
    return load_template @file_cache.template
  end
end

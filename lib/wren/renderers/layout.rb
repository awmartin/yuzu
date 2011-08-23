require 'haml'
require 'suppressor'
require 'content_handlers'
require 'renderers/breadcrumb'

class LayoutHandler

  def initialize(config, pageinfo)
    @pageinfo = pageinfo
    @html_title = pageinfo.html_title
    @link_root = pageinfo.link_root
    @config = config
    
    @suppressor = Suppressor.new
  end
  
  def load_page_partials metadata
    @html_head = load_partial "_head.haml", metadata
    @header_contents = load_partial "_header.haml", metadata
    @menu_contents = load_partial "_menu.haml", metadata
    
    recents = [] #get_recent_blog_posts(@config)
    titles = recents.collect {|entry| extract_title_from_filename entry}
    @footer_contents = load_partial "_footer.haml", metadata.update({:recents => recents, :titles => titles})
  end
  
  def load_template local_path="", data={}
    puts "Loading template " + local_path.to_s
    return "" if local_path.blank?
    
    local_path = File.join(@config.template_dir, local_path).to_s
    
    template = File.open(local_path, 'r')
    contents = template.readlines.join
    
    #@suppressor.shutup!
    result = Haml::Engine.new(contents, {:format => :html5}).render(Object.new, data)
    #@suppressor.ok
  
    return result
  rescue => detail
    puts detail.message
    return ""
  end

  # Loads the HAML partials for the layout. Especially _head.haml, _header.haml, 
  # _footer.haml, _menu.haml.
  def load_partial local_path="", data={}
    puts "Loading partial #{local_path}."
    return "" if local_path.blank?
    
    local_path = File.join(@config.template_dir, local_path).to_s
    
    partial = File.open(local_path, 'r')
    contents = partial.readlines.join
    crumbs = data.has_key?(:path) ? render_breadcrumb(data[:path], @config, @pageinfo) : ""
    
    local_vars = @config.config_dict.dup.update({ 
        :html_title => @html_title || "",
        :link_root => @link_root || "",
        :breadcrumb => crumbs || ""
      }).update(data)
    
    #@suppressor.shutup!
    result = Haml::Engine.new(contents, {:format => :html5}).render(Object.new, local_vars)
    #@suppressor.ok
  
    return result
  rescue => detail
    puts detail.message
    puts detail.backtrace
    return ""
  end
  
  def is_in_blog? path
    path.to_s.split("/").first == @config.blog_dir
  end
  
  # Puts the header and footer in place.
  def wrap_with_layout contents="", template="_generic.haml", metadata={}
    puts "wrap_with_layout, template=#{template}"
    # Check if this is in the blog. If so, then tell the breadcrumb it needs to render with categories.
    
    first_paragraph = metadata.has_key?(:first_paragraph) ? metadata[:first_paragraph] : ""
    categories = metadata.has_key?(:categories) ? metadata[:categories] : []
    page_links = metadata.has_key?(:page_links) ? metadata[:page_links] : ""
    post_title = metadata.has_key?(:post_title) ? metadata[:post_title] : "Untitled"
    html_title = metadata.has_key?(:html_title) ? metadata[:html_title] : @html_title
    
    if metadata.has_key?(:breadcrumb_path)
      
      # Post must be placed in the root blog folder for categories to kick in. Else, use the folder.
      num_paths = metadata[:breadcrumb_path].split("/").length
      
      # If this file is in the blog directory, send in the categories to the breadcrumb.
      if is_in_blog?(metadata[:breadcrumb_path]) and num_paths == 2
        breadcrumb = render_breadcrumb(metadata[:breadcrumb_path], @config, @pageinfo, categories)
      else
        breadcrumb = render_breadcrumb(metadata[:breadcrumb_path], @config, @pageinfo)
      end
    else
      breadcrumb = ""
    end
    
    load_page_partials metadata
    
    return load_template(template, {:head => @html_head,
                                    :contents => contents,
                                    :header => @header_contents,
                                    :footer => @footer_contents,
                                    :menu => @menu_contents,
                                    :sidebar_contents => metadata[:sidebar_contents],
                                    :first_paragraph => first_paragraph,
                                    :breadcrumb => breadcrumb,
                                    :post_title => post_title,
                                    :categories => categories,
                                    :page_links => page_links,
                                    :html_title => html_title})
  rescue => exception
    puts "Exception in wrap_with_layout..."
    puts exception.message
    puts exception.backtrace
  end

  def wrap_tag_contents tag, str
    level2 = str.to_s.split(tag)
    result = []
    level2.each_index do |i|
      if i>0
        str = level2[i]
        if tag == "h2."
          str = wrap_tag_contents "h3.", str
        elsif tag == "h3."
          str = wrap_tag_contents "h4.", str
        end
        result += [tag + str.sub("\n","\n\n<div class=\"level\">") + "</div>\n"]
      end
    end
    return level2[0] + result.join
  end

  def wrap_accordion str=""
    return wrap_slides str, true
  end

  # Slides are not recursive. Then are arranged linearly, one after another.
  def wrap_slides str="", after_tag=false
    return "" if str.blank?
    # Split by all headers first.
    headers = /h1\.\s|h2\.\s|h3\.\s|h4\.\s/
    slides = str.to_s.split(headers)
  
    first = slides.delete_at(0)
  
    if after_tag
      slides = slides.collect { |slide| 
        lines = slide.split("\n")
        title = lines.delete_at(0)
        slide = lines.join("\n")
        "h2. #{title}\n\n<div class=\"slide\">\n#{slide}\n\n</div>\n\n"
      }
    else
      slides = slides.collect { |slide| "<div class=\"slide\">\n\nh2. #{slide}</div>\n"}
    end
  
    return first + slides.join
  end

  def slideshow_path path=""
    ext = File.extname(path)
    return path if ext.blank?
    return path.sub(ext, "-slideshow"+ext)
  end

  def accordion_path path=""
    ext = File.extname(path)
    return path if ext.blank?
    return path.sub(ext, "-accordion"+ext)
  end
end
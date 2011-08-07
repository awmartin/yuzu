require 'haml'

require 'helpers'
require 'content_handlers'
require 'renderers/keyword_handlers'
require 'renderers/multiview'

class HamlRenderer
  def initialize(config, pageinfo, galleries=true)
    @config = config
    @pageinfo = pageinfo
    @galleries = galleries
  end
  
  def render str="", local_path=""
    str, template, metadata = preprocess_keywords(str, local_path, @config, @pageinfo, @galleries)
    return Haml::Engine.new(str, {:format => :html5, :ugly => false}).render(Object.new, { :html_title => @pageinfo.html_title } ), template, metadata
  rescue => exception
    puts "EXCEPTION in HamlRenderer.render"
    
    puts exception.message
    puts exception.backtrace
    
    return "", "_generic.haml", {}
  end
end
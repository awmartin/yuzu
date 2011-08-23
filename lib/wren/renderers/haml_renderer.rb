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
    contents, template, metadata = preprocess_keywords(str, local_path, @config, @pageinfo, @galleries)
    local_vars = {
      :html_title => metadata[:html_title]
      }
    opts = {
      :format => :html5
      }
    return Haml::Engine.new(contents, opts).render(Object.new, local_vars), template, metadata
  rescue => exception
    puts "EXCEPTION in HamlRenderer.render"
    
    puts exception.message
    puts exception.backtrace
    
    return "", "_generic.haml", {}
  end
end
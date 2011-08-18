require 'maruku'

require 'helpers'
require 'content_handlers'
require 'renderers/keyword_handlers'
require 'renderers/multiview'

class MarkdownRenderer
  include Wren::Helpers

  def initialize(config, pageinfo, galleries=true, strip_styles=false)
    @config = config
    @pageinfo = pageinfo
    @galleries = galleries
    @strip_styles = strip_styles
  end
  
  def render str="", local_path=""
    puts "Rendering markdown for #{local_path}..."
    if str.blank?
      puts "... returning prematurely. No contents given to MarkdownRenderer.render"
      return "", "_generic.haml", {} 
    end
    
    str, template, metadata = preprocess_keywords(str, local_path, @config, @pageinfo, @galleries)
      
    #if @strip_styles
    #  str = strip_styles(str)
    #end
  
    return Maruku.new(str).to_html.to_s, template, metadata
  
  rescue => exception
    puts "EXCEPTION in MarkdownRenderer.render"
    
    puts exception.message
    puts exception.backtrace
    
    return "", "_generic.haml", {}
  end

end
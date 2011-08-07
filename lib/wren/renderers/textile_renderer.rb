require 'RedCloth'

require 'helpers'
require 'content_handlers'
require 'renderers/keyword_handlers'
require 'renderers/multiview'

class TextileRenderer
  include Wren::Helpers

  def initialize(config, pageinfo, galleries=true, strip_styles=false)
    @config = config
    @pageinfo = pageinfo
    @galleries = galleries
    @strip_styles = strip_styles
  end
  
  def render str="", local_path=""
    puts "Rendering textile for #{local_path}..."
    if str.blank?
      puts "... returning prematurely. No contents given to TextileRenderer.render"
      return "", "_generic.haml", {} 
    end
    
    str, template, metadata = preprocess_keywords(str, local_path, @config, @pageinfo, @galleries)
      
    if @strip_styles
      str = strip_textile_styles(str)
    end
  
    return RedCloth.new(str).to_html.to_s, template, metadata
  
  rescue => exception
    puts "EXCEPTION in TextileRenderer.render"
    
    puts exception.message
    puts exception.backtrace
    
    return "", "_generic.haml", {}
  end
  
  def strip_textile_styles str
    return str.gsub(/p\([A-Za-z0-9]*\)\.\s/,"")
  end

end
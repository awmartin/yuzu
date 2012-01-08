require 'helpers'

class SlideshowRenderer
  include Wren::Helpers
  
  attr_accessor :raw_contents
  
  def initialize raw_contents, file_type
    @raw_contents = raw_contents
    @file_type = file_type
  end
  
  def render
    headers = nil
    if @file_type == :textile
      headers = /h1\.\s|h2\.\s|h3\.\s|h4\.\s/
    elsif @file_type == :markdown
      headers = /\n\#{1,6}\s/
    elsif @file_type == :haml
      headers = /\%h1\s|\%h2\s|\%h3\s|\%h4\s/
    end
    
    if headers.nil?
      return @raw_contents
    end
    
    # Split all the contents by headers
    slides = @raw_contents.to_s.split(headers)
    
    # Delete the prefacing content
    first = slides.delete_at(0)
    
    if @file_type == :textile
      preferred_header = "h2."
    elsif @file_type == :markdown
      preferred_header = "##"
    elsif @file_type == :haml
      preferred_header = "%h2"
    end
    
    slides = slides.collect { |slide| "\n\n<div class=\"slide\">\n\n#{preferred_header} #{slide}</div>\n\n"}
    
    return first + slides.join
  end
end
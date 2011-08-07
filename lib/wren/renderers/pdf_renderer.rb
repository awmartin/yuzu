require 'helpers'
require 'hpricot'
require 'prawn'

class PDFRenderer
  include Wren::Helpers
  
  attr_accessor :html
  
  def initialize html=""
    @html = html
  end
  
  def render local_path=""
    return if @html.nil?
    
    file_path = change_extension local_path, ".pdf"
    
    doc = Hpricot(@html)
    
    standard = {:size => 10, :leading => 4}
    
    Prawn::Document.generate file_path do |pdf|
      pdf.font "Helvetica"
      (doc/"/").each do |e|
        
        case e.name
        when 'h1'
          pdf.font "Helvetica-Bold", {:size => 20, :leading => 4}
          pdf.text e.inner_text, {:size => 20, :leading => 4}
        when 'h2'
          pdf.font "Helvetica-Bold", {:size => 18, :leading => 4}
          pdf.text e.inner_text, {:size => 18, :leading => 4}
        when 'h3'
          pdf.font "Helvetica-Bold", {:size => 16, :leading => 4}
          pdf.text e.inner_text, {:size => 16, :leading => 4}
        when 'h4'
          pdf.font "Helvetica-Bold", {:size => 14, :leading => 4}
          pdf.text e.inner_text, {:size => 14, :leading => 4}
        when 'p'
          pdf.font "Helvetica", standard
          pdf.text e.inner_text, standard
        when 'img'
          
        when 'a'
          pdf.font "Helvetica", standard
          pdf.text "<u>" + e.inner_text + "</u>", standard, :inline_format => true
        else
          pdf.font "Helvetica", standard
          pdf.text e.inner_text, standard
        end
        
      end
    end
  end
end
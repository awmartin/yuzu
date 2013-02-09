require 'kramdown'

module Wren::Filters
  class SidebarFilter < Filter
    def initialize
      @name = :sidebar
      @directive = "SIDEBAR"
    end

    def regex
      /SIDEBAR\{([\w\s\n\*\#\%\.\,\"\'\/\-\[\]\:\)\(<>_=]*)\}/
    end

    def default(website_file=nil)
      ""
    end

    def get_value(website_file)
      sidebar = match(website_file.raw_contents).to_s
      Kramdown::Document.new(sidebar).to_html
    end
  end
  Filter.register(:sidebar => SidebarFilter)
end


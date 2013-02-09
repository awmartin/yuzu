
module Wren::Filters
  class TemplateFilter < Filter
    def initialize
      @directive = "TEMPLATE"
      @name = :template
    end

    def default(website_file)
      "generic.haml"
    end
  end
  Filter.register(:template => TemplateFilter)
end


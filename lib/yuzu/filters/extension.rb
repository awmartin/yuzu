
module Yuzu::Filters
  class ExtensionFilter < Filter
    def initialize
      @name = :extension
      @directive = "OUTPUT"
    end

    def default(website_file=nil)
      ".html"
    end
  end
  Filter.register(:extension => ExtensionFilter)
end


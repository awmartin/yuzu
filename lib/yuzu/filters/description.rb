require 'filters/base'

module Yuzu::Filters
  class DescriptionFilter < Filter
    def initialize
      @name = :description
      @directive = "DESCRIPTION"
    end

    def default(website_file=nil)
      ""
    end
  end
  Filter.register(:description => DescriptionFilter)
end


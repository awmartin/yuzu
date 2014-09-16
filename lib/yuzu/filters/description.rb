require 'helpers/import'

import 'yuzu/filters/base'

module Yuzu::Filters
  class DescriptionFilter < Filter
    def initialize
      @name = :description
      @directive = "DESCRIPTION"
    end

    def default(website_file=nil)
      ""
    end

    def get_value(website_file)
      val = match(website_file.raw_contents)
      val.nil? ? nil : val.gsub("\n", "")
    end
  end
  Filter.register(:description => DescriptionFilter)
end


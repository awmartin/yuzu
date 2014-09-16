require 'helpers/import'

import 'yuzu/filters/base'
import 'helpers/path'

module Yuzu::Filters
  # Provides a way for a post to masquerade as another post. This enables the author to displace a
  # post in multiple places, typically a "Featured" folder that merely links to other posts in the
  # main content area.
  class LinkFilter < Filter
    def initialize
      @name = :link
      @directive = "LINK"
    end

    def default(website_file=nil)
      nil
    end

    # Returns the WebsiteFile referenced by the directive, or nil.
    def get_value(website_file)
      m = match(website_file.raw_contents)
      m.nil? ? nil : website_file.root.find_file_by_path(Helpers::Path.new(m))
    end

    # Remove the entire LINK(...) directive.
    def replacement(website_file, processing_contents=nil)
      ""
    end
  end
  Filter.register(:link => LinkFilter)
end


require 'helpers/import'

import 'yuzu/filters/base'

module Yuzu::Filters
  class LinkrootFilter < Filter
    def initialize
      @name = :linkroot
      @directive = "LINKROOT"
    end

    def filter_type
      # Filter the LINKROOT in IMAGES and other path-dependent tags first, so they have the proper
      # paths to search for. Then process LINKROOT afterwards.
      [:prefilter, :postfilter]
    end

    def regex
      /LINKROOT/
    end

    def get_value(website_file)
      website_file.config.linkroot
    end

    def get_match(contents)
      m = contents.match(regex)
      m.nil? ? nil : m[0]
    end

    def replacement(website_file, processing_contents=nil)
      website_file.config.linkroot
    end
  end
  Filter.register(:linkroot => LinkrootFilter)
end


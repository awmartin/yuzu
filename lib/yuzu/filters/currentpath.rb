require 'helpers/import'

import 'helpers/url'
import 'yuzu/filters/base'


module Yuzu::Filters
  class CurrentpathFilter < Filter
    include Helpers

    def initialize
      @name = :currentpath
      @directive = "CURRENTPATH"
    end

    def filter_type
      # Filter the LINKROOT in IMAGES and other path-dependent tags first, so they have the proper
      # paths to search for. Then process LINKROOT afterwards.
      [:prefilter, :postfilter]
    end

    def regex
      /CURRENTPATH/
    end

    def get_value(website_file)
      linkroot = website_file.config.linkroot
      pathname = website_file.path.dirname
      Url.new(pathname, prefix=linkroot)
    end

    def replacement(website_file, processing_contents=nil)
      get_value(website_file)
    end
  end
  Filter.register(:currentpath => CurrentpathFilter)
end


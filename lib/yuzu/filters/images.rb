require 'helpers/import'

import 'yuzu/filters/base'

module Yuzu::Filters
  class ImagesFilter < Filter
    def initialize
      @name = :images
      @directive = "IMAGES"
    end

    def default(website_file=nil)
      []
    end

    def get_value(website_file)
      m = match(website_file.raw_contents)
      return default if m.nil?

      images = m.split(",")
      images = images.collect {|img| img.strip}
      images = images.reject {|img| img.empty?}

      images = images.collect {|img|
        img = Filter.filters[:linkroot].process(website_file, img)
        Filter.filters[:currentpath].process(website_file, img)
      }

      images
    end
  end
  Filter.register(:images => ImagesFilter)
end


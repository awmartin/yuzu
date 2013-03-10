require 'helpers/import'

import 'yuzu/filters/base'
import 'yuzu/translators/base'

module Yuzu::Filters
  class SidebarFilter < Filter
    def initialize
      @name = :sidebar
      @directive = "SIDEBAR"
    end

    def regex
      /SIDEBAR\s*\{([\w\W]*?)\}/
    end

    def default(website_file=nil)
      ""
    end

    def get_value(website_file)
      sidebar = match(website_file.raw_contents).to_s
      Yuzu::Translators::Translator.translate(sidebar, website_file.path.extension)
    end
  end
  Filter.register(:sidebar => SidebarFilter)
end


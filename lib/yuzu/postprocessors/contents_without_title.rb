require 'helpers/import'
import 'yuzu/postprocessors/base'

module Yuzu::PostProcessors
  class ContentsWithoutTitle < PostProcessor
    def initialize
      @name = :contents_without_title
      @directive = "CONTENTSWITHOUTTITLE"
    end

    def regex
      /<h1\b[^>]*?>(.*?)<\/h1>/n
    end
    
    def match(contents)
      contents.to_s.sub(regex, "")
    end
  end
  PostProcessor.register(:contents_without_title => ContentsWithoutTitle)
end


require 'helpers/import'
import 'yuzu/postprocessors/base'

module Yuzu::PostProcessors
  class ContentsWithoutFirstParagraphPostProcessor < PostProcessor
    def initialize
      @name = :contents_without_first_paragraph
      @directive = "CONTENTSWITHOUTFIRSTPARAGRAPH"
    end

    def regex
      /<p\b[^>]*?>(.*?)<\/p>/n
    end

    def match(contents)
      contents.sub(regex, "")
    end
  end
  PostProcessor.register(:contents_without_first_paragraph => ContentsWithoutFirstParagraphPostProcessor)
end


require 'helpers/import'
import 'yuzu/postprocessors/base'

module Yuzu::PostProcessors
  class FirstParagraphPostProcessor < PostProcessor
    def initialize
      @name = :first_paragraph
      @directive = "FIRSTPARAGRAPH"
    end

    def regex
      /<p\b[^>]*?>([\w\W]*?)<\/p>/n
    end
  end
  PostProcessor.register(:first_paragraph => FirstParagraphPostProcessor)
end


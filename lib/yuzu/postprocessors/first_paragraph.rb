

module Yuzu::PostProcessors
  class FirstParagraphPostProcessor < PostProcessor
    def initialize
      @name = :first_paragraph
      @directive = "FIRSTPARAGRAPH"
    end

    def regex
      /<p\b[^>]*?>(.*?)<\/p>/n
    end
  end
  PostProcessor.register(:first_paragraph => FirstParagraphPostProcessor)
end


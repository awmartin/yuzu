
module Wren::PostProcessors
  class ExcerptPostProcessor < PostProcessor
    def initialize
      @name = :excerpt
      @directive = "EXCERPT"
    end

    def regex
      # Grab the entire paragraph, with the tag.
      /<p\b[^>]*?>.*?<\/p>/n
    end

    def match(contents)
      num_paragraphs = 5
      m = contents.scan(regex)
      m.nil? ? "" : m[0...5].join
    end
  end
  PostProcessor.register(:excerpt => ExcerptPostProcessor)
end


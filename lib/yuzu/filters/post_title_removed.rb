
module Yuzu::Filters
  class PostTitleRemovedFilter < Filter
    def initialize
      @directive = "POSTTITLEREMOVED"
      @name = :post_title_removed
    end

    def default(website_file)
      ""
    end

    def regex
      /^#\s+.*?\n/
    end

    def replacement(website_file, processing_contents=nil)
      if website_file.config.remove_h1_tags
        ""
      else
        processing_contents.match(regex)
      end
    end
  end
  Filter.register(:post_title_removed => PostTitleRemovedFilter)
end


require 'html/base'

module Yuzu::PostProcessors
  class PaginationPostProcessor < PostProcessor
    def initialize
      @name = :pagination
      @directive = "PAGINATION"
    end

    def value(website_file)
      root_file = website_file.paginated? ? website_file.original_file : website_file
      pagination_catalog = root_file.stash[:catalog]
      return "" if pagination_catalog.nil?
      num_pages = pagination_catalog.num_pages

      pages = [root_file] + root_file.stash[:paginated_siblings]

      links = pages.collect do |page|
        page_num = pages.find_index(page) + 1
        is_current_page = page == website_file
        if is_current_page
          Html::Span.new << page_num.to_s
        else
          Html::Link.new(:href => page.link_url) << page_num.to_s
        end
      end

      return Html::Div.new(:class => "pagination-links") << links.join(" ")
    end
  end
  PostProcessor.register(:pagination => PaginationPostProcessor)

end


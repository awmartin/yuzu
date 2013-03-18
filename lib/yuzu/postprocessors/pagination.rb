require 'helpers/import'
import 'html/base'
import 'yuzu/postprocessors/base'

module Yuzu::PostProcessors
  class PaginationPostProcessor < PostProcessor
    def initialize
      @name = :pagination
      @directive = "PAGINATION"
    end

    def value(website_file)
      root_file, pagination_catalog = get_pagination_catalog(website_file)
      return "" if pagination_catalog.nil?

      pages = [root_file] + root_file.stash[:paginated_siblings]

      links = get_links_for_pages(website_file, pages)

      return Html::Div.new(:class => "pagination-links") << links.join(" ")
    end

    def get_links_for_pages(current_page, pages)
      pages.collect { |page| get_link_for_page(current_page, page, pages) }
    end

    def get_link_for_page(current_page, page_being_linked_to, all_pages)
      page_num = all_pages.find_index(page_being_linked_to) + 1
      is_current_page = page_being_linked_to == current_page

      if is_current_page
        Html::Span.new << page_num.to_s
      else
        Html::Link.new(:href => page_being_linked_to.link_url) << page_num.to_s
      end
    end

    # Return the paginatable catalog attached to the given WebsiteFile.
    #
    # @param [WebsiteFile] website_file The root website file that initiates the pagination.
    # return [Catalog] The Catalog object that contains the rules and files to paginate.
    def get_pagination_catalog(website_file)
      root_file = website_file.paginated? ? website_file.original_file : website_file
      return root_file, root_file.stash[:source_catalog]
    end

  end
  PostProcessor.register(:pagination => PaginationPostProcessor)

end


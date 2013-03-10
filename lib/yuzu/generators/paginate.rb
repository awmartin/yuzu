require 'helpers/import'

import 'yuzu/generators/base'
import 'yuzu/core/paginated_file'


module Yuzu::Generators
  # The PaginateGenerator is responsible for creating new files that contain the overflow from
  # paginated Catalogs. If a Catalog rendered in index.md (which becomes index.html) has 22 items
  # and each page contains 10, this Generator will produce 2 new WebsiteFiles (index_2.html and
  # index_3.html) that contain the overflowed Catalog entries.
  #
  # This generator stashes the generated, paginated pages into the WebsiteFile's stash. Access with
  # WebsiteFile.stash[:paginated_siblings]
  class PaginateGenerator < Generator

    @@generated = []
    def self.get_generated
      @@generated
    end

    def self.add_generator(generator)
      @@generated.push(generator)
    end

    def self.is_generated?(generator)
      @@generated.include?(generator)
    end

    def initialize
      @name = "paginate"
      @directive = "INSERTCATALOG"
    end

    def should_generate?(website_file)
      not PaginateGenerator.is_generated?(website_file) and \
        not website_file.raw_contents.scan(regex).flatten.empty?
    end

    def visitor_filter
      proc {|c| c.file?}
    end

    def generate!(website_file)
      # Attempt to ensure this website_file isn't generated twice.
      return if website_file.is_a?(Yuzu::Core::PaginatedWebsiteFile) or \
        PaginateGenerator.is_generated?(website_file)

      CatalogPaginator.new(website_file, self).generate!
      PaginateGenerator.add_generator(website_file)
    end
  end
  Generator.register(:paginate => PaginateGenerator)


  # The CatalogPaginator determines whether each catalog requires pagination and performs the action
  # of producing new WebsiteFile objects for the first paginated catalog. Each one of these new
  # WebsiteFiles is identical to the source, except that its INSERTCATALOG(...) is replaced with a
  # non-paginatable version, with an explicit page number. The new WebsiteFiles are added to the
  # parent folder.
  class CatalogPaginator
    def initialize(website_file, catalog_generator)
      @website_file = website_file
      @catalog_generator = catalog_generator
    end

    def generate!
      catalog_args = @website_file.raw_contents.scan(@catalog_generator.regex).flatten
      catalogs = catalogs_from_args(catalog_args)
      generate_files_from_catalogs!(catalogs)
    end

    def generate_files_from_catalogs!(catalogs)
      paginating_catalogs = catalogs.select {|cat| cat.should_paginate?}

      # We can only really paginate the first paginatable catalog.
      first_paginating_catalog = paginating_catalogs.empty? ? nil : paginating_catalogs[0]

      generate_files_for_paginating_catalog!(first_paginating_catalog)
    end

    # Return an Array of Catalog instances from the given user-specified catalog arguments.
    #
    # @param [Array] catalog_args An Array of Hashes containing the arguments gathered from the
    #   INSERTCATALOG directives of the page.
    # @return [Array] An Array of corresponding Catalog objects.
    def catalogs_from_args(catalog_args)
      catalog_args.collect {|args| Yuzu::Filters.catalog_for(@website_file, args)}
    end

    # Given a Catalog instance, check to see if it requires pagination and generate the appropriate
    # files for the given content.
    # 
    # @param [Catalog] catalog The Yuzu::Generator.Catalog object that represents the contents to
    #   insert into the page.
    # @return nothing
    def generate_files_for_paginating_catalog!(catalog)
      return if catalog.nil?

      num_pages = catalog.num_pages
      return if num_pages == 1

      # Don't generate the first page, it's all ready to go.
      num_pages_to_generate = num_pages - 1
      num_pages_to_generate.times do |page|
        generate_page!(page + 2, catalog)
      end
    end

    # Add a single PaginatedWebsiteFile instance and add it to the parent of the given WebsiteFile
    # as a sibling for the specified page of the given Catalog.
    #
    # @param [Fixnum] page The page to generate, indexed by 1.
    # @param [Catalog] catalog The Catalog being paginated.
    # @return nothing
    def generate_page!(page, catalog)
      original_directive = catalog.original_directive
      directive_for_page = catalog.directive_for_page(page)

      new_raw_contents = @website_file.raw_contents.sub(original_directive, directive_for_page)

      paginated_file = Yuzu::Core::PaginatedWebsiteFile.new(@website_file, new_raw_contents, page)
      add_file(paginated_file)
    end

    # Takes the PaginatedWebsiteFile instance and adds it as a sibling to the root WebsiteFile being
    # paginated.
    #
    # @param [PaginatedWebsiteFile] paginated_file The new page to add as a sibling.
    # @return nothing
    def add_file(paginated_file)
      container = @website_file.parent
      container.append_child(paginated_file)
      stash_paginated_file(paginated_file)
    end

    # Registers the generated file in the seed file's stash, enabling us to generate pagination
    # links and other niceties later.
    # 
    # @param [PaginatedWebsiteFile] paginated_file A file to add.
    # @return nothing
    def stash_paginated_file(paginated_file)
      paginated_siblings = @website_file.stash[:paginated_siblings] || []
      @website_file.stash(:paginated_siblings => paginated_siblings + [paginated_file])
    end

  end
end


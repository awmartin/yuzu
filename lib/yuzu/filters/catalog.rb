require 'helpers/import'

import 'html/base'
import 'helpers/path'
import 'helpers/string'
import 'yuzu/filters/base'
import 'yuzu/core/template'


module Yuzu::Filters
  include Yuzu::Core

  # The CatalogFilter enables authors to insert collections of pages and posts from any folder in
  # the site. The INSERTCATALOG() directive can be used to specify the target folder containing the
  # posts, the sort order, Categories to filter by, and various information regarding the number of
  # files to render and the pagination rules.
  #
  # Catalogs are paginated according to the number of available files and the specified page limits
  # in the pagination pass. See PaginateGenerator for information about how the pagination is
  # handled. Generally, INSERTCATALOG directives that don't have a specific page number and that
  # have an overflow will produce new WebsiteFile objects that handle the overflow.
  class CatalogFilter < Filter
    def initialize
      @name = :catalog
      @directive = "INSERTCATALOG"
    end

    # The "catalog" method attached to WebsiteFile instances doesn't really have a value. The actual
    # Catalog being paginated is placed in the WebsiteFile's stash.
    def value(website_file)
      nil
    end

    # Replace the INSERTCATALOG directive with the HTML String that contains the rendered Catalog.
    def replacement(website_file, processing_contents=nil)
      catalog = Yuzu::Filters.catalog_for(website_file, match(processing_contents))

      if catalog.should_paginate? and catalog.num_pages > 1
        # Store the original, paginatable catalog in the root file.
        website_file.stash(:source_catalog => catalog)
      end

      catalog.render
    end
  end
  Filter.register(:catalog => CatalogFilter)


  # Create a Catalog instance for a given match
  #
  # @param [WebsiteFile] website_file The file in which the catalog is being rendered.
  # @param [String] match_string The match given by the filter, e.g. "page:1, per_row:3, ..."
  # @return [Catalog] The catalog object responsible for rendering the pages specified.
  def catalog_for(website_file, match_string)
    kwds = Yuzu::Filters.get_kwds(match_string)
    Catalog.new(kwds, website_file, match_string)
  end
  module_function :catalog_for

  # Returns a Hash of the keyword arguments contained in the inner match string of the tag:
  #
  #     INSERTCATALOG(page: 1, count:10)
  #
  # yields
  #
  #     {:page => 1, :count => 10}
  #
  # @param [String] match_string The text inside the tag match.
  # @return [Hash] The key to value pairs.
  def get_kwds(match_string)
    pairs = match_string.split(",").collect {|pair| pair.strip}

    kwds = {}
    pairs.each do |pair|
      key, val = pair.split(":").collect {|el| el.strip}
      kwds[key.to_sym] = val
    end

    kwds
  end
  module_function :get_kwds


  # Catalogs render one page of collected contents and have no knowledge of pagination. The
  # auto-pagination happens earlier as part of the generation process (see the PaginateGenerator and
  # CatalogPaginator classes).
  class Catalog
    include Helpers
    attr_reader :website_file

    # Create a new Catalog instance.
    #
    # @param [Hash] kwds The arguments from the INSERTCATALOG directive.
    # @param [WebsiteFile] The WebsiteFile that contains the Catalog being rendered.
    # @param [String] original_match_string The string between the parentheses of the INSERTCATALOG
    #   directive.
    def initialize(kwds, website_file, original_match_string)
      @kwds = kwds
      @website_file = website_file
      @original_match_string = original_match_string

      @siteroot = website_file.root
    end

    # Define accessors for each of the given keyword arguments.
    @@kwd_defaults = {
      :template => '_block.haml',
      :total => 1000,
      :per_page => 10,
      :per_row => 1,
      :page => 1,
      :offset => 0,
      :category => nil,
      :sort => :post_date_reversed,
      :split_rows => true
    }
    @@kwd_defaults.each_pair do |key, default_value|
      define_method key do
        if @kwds.has_key?(key)
          # The user's arguments always come in as a String, so this converts the argument into its
          # appropriate type as specified by the defaults Hash.
          convert_method = get_default_type_method(key)
          convert_method.nil? ? @kwds[key] : @kwds[key].send(convert_method)
        else
          default_value
        end
      end
    end

    def to_s
      "Catalog(#{@website_file}, page:#{page})"
    end

    # Given a key from the default keyword arguments of the INSERTCATALOG directive, return the
    # method as a Symbol that can convert the parsed value String into the appropriate type.
    #
    # @param [Symbol] key The argument key.
    # @return [Symbol] A method that when sent to the parsed value will convert it to the correct
    #   type.
    def get_default_type_method(key)
      klass = get_default_type(key)
      if klass == String
        :to_s
      elsif klass == Fixnum
        :to_i
      elsif klass == Float
        :to_f
      elsif klass == Symbol
        :to_sym
      elsif klass == TrueClass
        :to_bool
      elsif klass == FalseClass
        :to_bool
      else
        nil
      end
    end

    # Given a key from the arguments of INSERTCATALOG, return the Ruby type of the acceptable values
    # for the key.
    #
    # @param [Symbol] key The argument key.
    # @return [Class] The Ruby class of values of the key.
    def get_default_type(key)
      @@kwd_defaults.has_key?(key) ? @@kwd_defaults[key].class : nil
    end

    @@normal_order = [:post_date, :post_title, :created_at, :modified_at]
    @@reverse_order = [:post_date_reversed, :post_title_reversed, :created_at_reversed, :modified_at_reversed]

    # The Symbol representing the field to sort by, regardless of the normal/reverse order.
    def sort_field
      @sort_field ||= ordered_sort_field.to_s.sub("_reversed", "").to_sym
    end

    # The Symbol representing the author-specified sort order for the Catalog.
    def ordered_sort_field
      (@@normal_order + @@reverse_order).include?(sort) ? sort : @@kwd_defaults[:sort]
    end

    # The normal/reverse order to sort by.
    #
    # @return [Symbol]
    def sort_order
      @@reverse_order.include?(ordered_sort_field) ? :reversed : :normal
    end

    # Return whether this Catalog represents one that should be paginated.
    #
    # @return [Boolean]
    def should_paginate?
      num_total_files > number_of_files_to_show
    end

    # Return the total number of files to be rendered by the paginatable Catalog.
    #
    # @return [Fixnum]
    def num_total_files
      [target_files.length, total].min
    end

    # The number of pages this Catalog will hold if it is paginatable. Catalogs after the pagination
    # pass will always represent 1 page.
    #
    # @return [Fixnum]
    def num_pages
      return 1 if not should_paginate?
      (num_total_files.to_f / per_page.to_f).ceil
    end

    # The original INSERTCATALOG directive that this Catalog comes from. This is used to replace the
    # paginatable Catalogs with the first page of the pagination.
    #
    # @return [String]
    def original_directive
      # TODO build a regex forgiving of whitespace
      "INSERTCATALOG(#{@original_match_string})"
    end

    # Returns a DIRECTIVE tag that contains the 'page' key for the new paginated catalog. When
    # pagination occurs, the contents of the original file are duplicated, but the INSERTCATALOG
    # directive being paginated is replaced with a new directive that contains the explicit page
    # number. That way, once the pagination pass is complete, the site should contain only Catalogs
    # that are ready to be rendered directly.
    #
    # @param [Fixnum] page The page that the new INSERTCATALOG directive should represent.
    def directive_for_page(page)
      with_page = @kwds.merge({:page => page})
      args = with_page.collect {|key, val| "#{key}:#{val}"}.join(", ")
      "INSERTCATALOG(#{args})"
    end

    def formatted_directive
      args = @kwds.collect {|key, val| "#{key}:#{val}"}.join(", ")
      "INSERTCATALOG(#{args})"
    end

    # Returns the rendered Catalog as a String.
    def render
      if well_formed?
        rows = []
        num_rows_this_page.times do |row|
          rows.push(render_nth_row(row))
        end
        rows.join("\n")
      else
        Html::Comment.new << "Error in processing the catalog. Got #{formatted_directive}"
      end
    end

    # Renders the nth row of a catalog grid.
    #
    # @param [Fixnum] row Which row to render, zero-indexed.
    # @return [String] The HTML results rendered as a String.
    def render_nth_row(row)
      start = row * per_row
      stop = (row + 1) * per_row
      files_this_row = files_to_render_this_page[start...stop]
      if files_this_row.empty?
        Html::Div.new(:class => 'row') << Html::Comment.new << "No files in this row."
      else
        render_row(files_this_row)
      end
    end

    # Returns an HTML formatted row of files rendered in the appropriate template.
    #
    # @param [Array] files An Array of WebsiteFile instances that should appear in a particular row
    #   of the catalog grid.
    # @return [String] The HTML tag containing the row as a String.
    def render_row(files)
      rendered_files = files.collect {|file| render_post(file)}.join("\n")
      if split_rows
        Html::Div.new(:class => 'row') << rendered_files
      else
        rendered_files
      end
    end

    # Renders a single WebsiteFile contained in the Catalog with the specified template.
    #
    # @param [WebsiteFile] file The file to be rendered.
    # @return [String] An HTML formatted String with the rendered, templated contents of the file.
    def render_post(file)
      partial.render(file, {:klass => css_class})
    end

    # Builds a CSS class string that decorates each rendered pst with appropriate sizing and
    # appearance information.
    #
    # @return [String] The CSS class for a single <div> tag surrounding a post.
    def css_class
      num_columns_12 = (12.0 / per_row).floor
      "span#{num_columns_12}"
    end

    # Returns the template used to render individual posts in thie catalog.
    #
    # @return [HamlTemplate] The template used for rendering.
    def partial
      @catalog_partial ||= Yuzu::Core::HamlTemplate.new(template)
    end

    # Returns whether the Catalog has enough information to be rendered. Does not imply correctness.
    #
    # @return [Boolean]
    def well_formed?
      @kwds.has_key?(:path)
    end

    # Returns the target files sorted and filtered.
    #
    # @return [Array] An Array of WebsiteFile instances contained by the target folder.
    def target_files
      @target_files ||= get_target_files
    end

    # Calculates the child WebsiteFile instances represented by this Catalog and returns them in the
    # specified sort order, filtered by the current Catalog.
    #
    # @return [Array] An Array of WebsiteFile instances contained by the target folder.
    def get_target_files
      filtered = get_category_filtered_target_files(get_unsorted_target_files)
      get_sorted_target_files(filtered)
    end

    # Apply the current Catalog sorting to the given files.
    #
    # @param [Array] An Array of WebsiteFile to be sorted.
    # @return [Array] An Array of WebsiteFile instances in the specified order.
    def get_sorted_target_files(files)
      if sort_order == :normal
        files.sort {|a, b| a.send(sort_field) <=> b.send(sort_field)}
      else
        files.sort {|a, b| b.send(sort_field) <=> a.send(sort_field)}
      end
    end

    # Return all the files contained in the target folder that are tagged with the Category
    # specified in the INSERTCATALOG directive. If no category is specified, all target files are
    # returned
    #
    # @param [Array] files The files to be filtered by category.
    # @return [Array] The WebsiteFile instances that are tagged with the current Category.
    def get_category_filtered_target_files(files)
      category.nil? ? files : files.select {|file| file_has_category?(file)}
    end

    # Return all the files contained by the target_folder.
    #
    # @return [Array] An Array of all WebsiteFile instances contained in target_folder.
    def get_unsorted_target_files
      return [] if target_folder.nil?
      tr = target_folder.all_processable_children.reject {|node| node.index?}

      # Replace all links with their targets.
      tr.collect {|f| f.is_link? ? f.link : f }
    end

    # Get the WebsiteFolder that the 'path' key in the Catalog directive refers to.
    #
    # @return [WebsiteFolder] The folder refered to by 'path:'
    def target_folder
      case
      when (not well_formed?)
        nil
      when @kwds[:path] == ""
        @siteroot
      else
        search_path = Path.new(@kwds[:path])
        @siteroot.find_file_by_path(search_path)
      end
    end

    # Return whether the given file is tagged with at least one Category.
    #
    # @param [WebsiteFile] file The file to check.
    # @return [Boolean]
    def file_has_category?(file)
      file.categories.each do |cat|
        if cat.name == category.downcase.dasherize
          return true
        end
      end
      false
    end

    # Returns an array of WebsiteFile objects that are the contents of the catalog on this page.
    #
    # @return [Array]
    def files_to_render_this_page
      start = (page - 1) * per_page + offset
      stop = page * per_page + offset
      target_files[start...stop]
    end

    # Return whether the Catalog includes a WebsiteFile on this page.
    #
    # @param [WebsiteFile] other The file to check inclusion.
    # @return [Boolean] Whether the file is included.
    def include?(other)
      files_to_render_this_page.include?(other)
    end

    # The number of rows to be rendered by this Catalog.
    #
    # @return [Fixnum] The number of horizontal rows that contain WebsiteFiles.
    def num_rows_this_page
      (number_of_files_to_show.to_f / per_row.to_f).ceil
    end

    # Return the number of files to actually show on this page, given that the page may not be full
    # and that the 'total' and 'per_page' limits are in place.
    #
    # @return [Fixnum] The number of files on this page.
    def number_of_files_to_show
      [total, per_page, target_files.length, page * per_page].min
    end

  end
end



require 'core/template'
require 'helpers/path'
require 'html/base'


module Wren::Filters
  include Wren::Core

  class CatalogFilter < Filter
    def initialize
      @name = :catalog
      @directive = "INSERTCATALOG"
    end

    def value(website_file)
      nil
    end

    def replacement(website_file, processing_contents=nil)
      catalog = Wren::Filters.catalog_for(website_file, match(processing_contents))

      if catalog.should_paginate? and catalog.num_pages > 1
        website_file.stash(:catalog => catalog)
      end

      return catalog.render
    end
  end
  Filter.register(:catalog => CatalogFilter)


  # Create a Catalog instance for a given match
  #
  # @param [WebsiteFile] website_file The file in which the catalog is being rendered.
  # @param [String] match_string The match given by the filter, e.g. "page:1, per_row:3, ..."
  # @return [Catalog] The catalog object responsible for rendering the pages specified.
  def catalog_for(website_file, match_string)
    kwds = Wren::Filters.get_kwds(match_string)
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
  # auto-pagination happens earlier as part of the generation process.
  class Catalog
    include Helpers
    attr_reader :website_file

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
      :offset => 0
    }
    @@kwd_defaults.each_pair do |key, default_value|
      define_method key do
        convert = default_value.is_a?(String) ? :to_s : :to_i
        @kwds.has_key?(key) ? @kwds[key].send(convert) : default_value
      end
    end

    def should_paginate?
      num_total_files > number_of_files_to_show
    end

    def num_total_files
      [target_files.length, total].min
    end

    def num_pages
      return 1 if not should_paginate?
      (num_total_files.to_f / per_page.to_f).ceil
    end

    def original_directive
      # TODO build a regex forgiving of whitespace
      "INSERTCATALOG(#{@original_match_string})"
    end

    def directive_for_page(page)
      with_page = @kwds.merge({:page => page})
      args = with_page.collect {|key, val| "#{key}:#{val}"}.join(", ")
      "INSERTCATALOG(#{args})"
    end

    def formatted_directive
      args = @kwds.collect {|key, val| "#{key}:#{val}"}.join(", ")
      "INSERTCATALOG(#{args})"
    end

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

    def render_row(files)
      rendered_files = files.collect {|file| render_post(file)}.join("\n")
      Html::Div.new(:class => 'row') << rendered_files
    end

    def render_post(file)
      partial.render(file, {:klass => css_class})
    end

    def css_class
      num_columns_12 = (12.0 / per_row).floor
      "span#{num_columns_12}"
    end

    def partial
      Wren::Core::HamlTemplate.new(template)
    end

    def well_formed?
      @kwds.has_key?(:path)
    end

    def target_folder
      case
      when (not well_formed?)
        nil
      when @kwds[:path] == ""
        @siteroot
      else
        @siteroot.find_file_by_path(Path.new(@kwds[:path]))
      end
    end

    def target_files
      @target_files ||= get_target_files
    end

    def get_target_files
      return [] if target_folder.nil?
      unsorted = target_folder.all_processable_children.reject {|node| node.index?}
      sorted = unsorted.sort {|a, b| b.modified_at <=> a.modified_at}
      return sorted
    end

    # Returns an array of WebsiteFile objects that are the contents of the catalog on this page.
    def files_to_render_this_page
      start = (page - 1) * per_page + offset
      stop = page * per_page + offset
      target_files[start...stop]
    end

    def num_rows_this_page
      (number_of_files_to_show.to_f / per_row.to_f).ceil
    end

    def number_of_files_to_show
      [total, per_page, target_files.length, page * per_page].min
    end

  end
end



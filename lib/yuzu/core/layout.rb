require 'helpers/import'

import 'yuzu/core/template'


module Yuzu::Core
  # A Layout is a Template that lays out an entire page. It consists of a collection of partial
  # templates, namely for the HTML <head>, but also for a page header, footer, and navigation menu.
  # In the future, this will be generalized.
  class Layout < Yuzu::Core::HamlTemplate
    # The standard page partials.
    #def self.partial_names
    #  #%w(head header footer menu)
    #end

    # A hash of partial name to filename.
    #
    # @return [Hash]
    def self.partial_filenames
      relative_paths = Dir[(@@template_dir + "*").to_s]
      files = relative_paths.collect {|p| File.basename(p)}
      files.select {|filename| filename[0].chr == "_"}
    end

    # A hash of partial name to the corresponding HamlTemplate object for that partial.
    #
    # @return [Hash] of String => HamlTemplate
    def self.partials
      @@partials ||= get_partials
    end

    # Calculates the Hash for self.partials.
    def self.get_partials
      tr = {}
      partial_filenames.each do |filename|
        partial_name = filename[1...-5]
        tr[partial_name] = HamlTemplate.new(filename)
      end
      tr
    end

    # A Hash of all the local variables passed into the Haml engine when the layout is rendered.
    #
    # @param [WebsiteFile] website_file The website file being rendered.
    # @return [Hash] of local variables available in the template.
    def layout_locals(website_file)
      {:layout => PageLayout.new(website_file, Layout.partials)}
    end

    # Actually renders the layout for the given file.
    #
    # @param [WebsiteFile] website_file The website_file being rendered in the layout.
    # @return [String] A string containing the HTML rendered contents of the file as a webpage.
    def render(website_file)
      # Contains the standard local variables `post` and `config`.
      local_variables = locals(website_file)

      # Add `layout` to the mix.
      layout_local_variables = layout_locals(website_file)

      engine.render(
        Yuzu::Core::TemplateMethods.new(website_file.root),
        local_variables.merge(layout_local_variables)
      )
    end
  end


  # A class that encapsulates the variables in the `layout` namespace in the Haml layout. This means
  # that the user can access variables passed into the `kwds` hash with dot notation on `layout`.
  # For example:
  #
  #     layout.head - Refers to the rendered contents of _head.haml
  #
  class PageLayout
    def initialize(website_file, kwds={})
      kwds.each_pair do |method_name, template_obj|
        (class << self; self; end).class_eval do
          define_method method_name.to_sym do
            template_obj.render(website_file)
          end
        end
      end
    end
  end

end


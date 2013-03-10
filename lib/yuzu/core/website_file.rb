require 'helpers/import'

import 'html/base'

import 'yuzu/core/layout'
import 'yuzu/core/website_base'
import 'yuzu/filters/base'
import 'yuzu/renderers/base'
import 'yuzu/preprocessors/base'
import 'yuzu/postprocessors/base'
import 'yuzu/translators/base'


%w(filters renderers preprocessors postprocessors translators).each do |folder|
  Dir.glob(File.join(File.dirname(__FILE__), "..", folder, "*")).each do |c|
    import c if not c.include?("base.rb")
  end
end


module Yuzu::Core

  # A WebsiteFile represents a single web page, usually rendered as HTML. It is typically mapped
  # directly to a file on disk, with textual authored content.
  #
  # For example, a file "index.md" will be represented by a WebsiteFile, which is responsible for
  # loading the content and processing it into HTML (index.html) through a series of
  # transformations.
  class WebsiteFile < WebsiteBase
    include Yuzu::Filters
    include Yuzu::Renderers
    include Yuzu::PreProcessors
    include Yuzu::PostProcessors
    include Yuzu::Translators

    def self.translators
      Translator.translators
    end

    def self.processors
      Filter.filters.merge(Renderer.renderers)
    end

    # Create an accessor method for each filter, renderer, postprocessor.
    self.processors.each_pair do |name, object|
      execution_method = object.kind_of?(Renderer) ? :render : :value

      instance_variable = "@#{name}".to_sym

      define_method(name) do
        val = self.instance_variable_get(instance_variable)

        if val.nil?
          self.instance_variable_set(
            instance_variable,
            object.send(execution_method, self)
          )
        end

        self.instance_variable_get(instance_variable)
      end
    end

    # Adds all the postprocessors to this object as methods.
    PostProcessor.postprocessors.each_pair do |name, processor|

      define_method name do
        # This routine caches the result in an instance variable.
        instance_variable = "@postprocessor_#{name}".to_sym
        begin
          if instance_variable_get(instance_variable).nil?
            result = processor.value(self)
            instance_variable_set(instance_variable, result)
          end
          instance_variable_get(instance_variable)
        rescue => e
          $stderr.puts "\033[91mEXCEPTION IN #{name}\033[0m"
          $stderr.puts e.message
          $stderr.puts e.backtrace
        end
      end

    end

    attr_reader :page, :parent, :path

    # @param [Path] path The path of the source file on disk.
    # @param [WebsiteFolder] parent The folder that contains this file.
    # @param [Fixnum] page The page of this file in a set of paginated files.
    def initialize(path, parent, page=1)
      @path = path
      raise "@path is nil for #{self}" if @path.nil?

      @parent = parent
      @page = page

      @kind = :file
    end

    # Returns an object that holds the "properties" of this file, like the post_title, etc. This is
    # used to provide access to this file's attributes using dot notation in a HAML template. When
    # you refer to "post.post_title" in a template or layout, it's the result of this method that is
    # referred to by "post".
    def properties
      @properties ||= FileProperties.new(self)
    end

    def to_s
      "WebsiteFile(#{@path.relative})"
    end

    # The display name of this file.
    def name
      post_title
    end

    def author
      config.author
    end

    def home?
      parent.root? and index?
    end

    def index?
      basename == "index" or basename.include?("index_")
    end

    def filename
      @path.filename
    end

    def basename
      @path.basename
    end

    def output_filename
      processable? ? @path.with_extension(extension).filename : filename
    end

    def markdown?
      @path.markdown?
    end

    def plaintext?
      @path.plaintext?
    end

    # Alias
    def link_root
      linkroot
    end

    def paginated?
      false
    end

    def raw_contents
      if @raw_contents.nil?
        @raw_contents = get_raw_contents
        preprocess!
      end
      @raw_contents
    end

    def get_raw_contents
      f = File.open(@path.absolute, "r")
      contents = f.read
      f.close
      contents
    end

    # Returns the creation time of the file this website file represents.
    #
    # @return [Time] The creation time of the file on disk.
    def created_at
      @created_at ||= @path.pathname.ctime
    end

    # Returns the modification time of the file this website file represents.
    #
    # @return [Time] The last modified time of the file on disk.
    def modified_at
      @modified_at ||= @path.pathname.mtime
    end

    # Executes the preprocessors.
    def preprocess!
      PreProcessor.preprocessors.each do |name, preprocessor|
        preprocessor.process(self, @raw_contents)
      end
    end

    # Returns the raw contents passed through the prefilters.
    #
    # @return [String] The prefiltered contents.
    def prefiltered_contents
      @prefiltered_contents ||= get_prefiltered_contents
    end

    def get_prefiltered_contents
      tr = raw_contents
      prefilters.each do |filter|
        tr = filter.process(self, tr)
      end
      tr
    end

    # Returns the prefiltered contents passed through the main filters and postfilters.
    #
    # @return [String] the processed contents
    def processed_contents
      @processed_contents ||= get_processed_contents
    end

    def get_processed_contents
      tr = prefiltered_contents
      (mainfilters + postfilters).each do |filter|
        tr = filter.process(self, tr)
      end
      tr
    end

    # Return the results of running the processed_contents through the textual translators, e.g.
    # markdown to HTML translator.
    #
    # @return [String] the file's html-rendered contents
    def rendered_contents
      @rendered_contents ||= Translator.translate(processed_contents, @path.extension)
    end

    def layout
      @layout ||= Yuzu::Core::Layout.new(template)
    end

    # Presents the rendered_contents placed into its layout. The postprocessors act on this to
    # produce the values needed for html_contents.
    def layout_contents
      layout.render(self)
    end

    # The user-facing entry for post.contents in the Haml templates.
    def contents
      rendered_contents
    end

    # Renders the full, rendered HTML to write to disk.
    def html_contents
      layout_contents
    end

    def filters
      Filter.filters
    end

    def prefilters
      @prefilters ||= filters.values.select {|filt| filt.filter_type.include?(:prefilter)}
    end

    def mainfilters
      @mainfilters ||= filters.values.select {|filt| filt.filter_type.include?(:filter)}
    end

    def postfilters
      @postfilters ||= filters.values.select {|filt| filt.filter_type.include?(:postfilter)}
    end

  end


  # FileProperties objects are passed into renderers when they need to pass information
  # to a Haml template or other user-facing mechanism. e.g. This makes "breadcrumb" available in
  # Haml templates and layouts by using post.breadcrumb.
  class FileProperties

    # Initialize a new FileProperties to represent a WebsiteFile. This mirrors all the unique
    # public instance methods from the WebsiteFile so they can be accessed with "post" in a
    # template.
    #
    # @param [WebsiteFile] website_file The page this object will represent.
    # @return nothing
    def initialize(website_file)

      @website_file = website_file
      unique_methods = (website_file.methods - Object.instance_methods).sort

      (class << self; self; end).class_eval do

        unique_methods.each do |method_name|

          define_method(method_name) do |*args|
            website_file.send(method_name, *args)
          end

        end
      end # class_eval

    end # initialize

    def to_s
      "Properties(#{@website_file.path.relative})"
    end
  end

end


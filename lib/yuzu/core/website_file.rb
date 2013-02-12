require 'html/base'
require 'core/website_base'
require 'core/layout'

require 'filters/base'
require 'renderers/base'
require 'preprocessors/base'
require 'postprocessors/base'
require 'translators/base'

%w(filters renderers preprocessors postprocessors translators).each do |folder|
  Dir["#{File.dirname(__FILE__)}/../#{folder}/*"].each { |c| require c if not c.include?("base.rb")}
end

module Yuzu::Core
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
      tr = Filter.filters.merge(Renderer.renderers)
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
          puts "\033[91mEXCEPTION IN #{name}\033[0m"
          #puts e.message
          #puts e.backtrace
        end
      end

    end

    attr_reader :page, :parent, :path

    def initialize(path, parent, page=1)
      @path = path
      raise "@path is nil for #{self}" if @path.nil?

      @parent = parent
      @page = page

      @kind = :file
    end

    # Returns a Hash of the properties of this file, like the name, etc.
    def properties
      @properties ||= FileProperties.new(self)
    end

    def to_s
      "WebsiteFile(#{@path.relative})"
    end

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

    def created_at
      @created_at ||= @path.pathname.ctime
    end

    def modified_at
      @modified_at ||= @path.pathname.mtime
    end

    def preprocess!
      PreProcessor.preprocessors.each do |name, preprocessor|
        preprocessor.process(self, @raw_contents)
      end
    end

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

    # Returns the contents passed through the filters.
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

    # Return the results of running the processed_contents through the textual processors, e.g.
    # markdown.
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
    # instance.methods == public instance methods
    def initialize(website_file)

      @website_file = website_file
      unique_methods = (website_file.methods - Object.instance_methods).sort

      (class << self; self; end).class_eval do

        unique_methods.each do |method_name|

          define_method(method_name) do
            website_file.send(method_name)
          end

        end
      end # class_eval

    end # initialize

    def to_s
      "Properties(#{@website_file.path.relative})"
    end
  end

end

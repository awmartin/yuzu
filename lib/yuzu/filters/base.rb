require 'core/registrar'

module Yuzu::Filters
  include Yuzu::Registrar

  # Filters are the primary means to derive information from a given source file and place new
  # contents into it before it is placed in a layout.
  # 
  # There are 3 stages of filtering that happen to each file.
  #
  # 1. prefilter -- replacing LINKROOT and CURRENTPATH, so the next phase has the proper paths
  # 2. filter -- transforming contents
  # 3. postfilter -- replacing LINKROOT and CURRENTPATH again
  class Filter < Register
    @@filters = {}
    def self.registry
      :filters
    end
    def self.filters
      @@filters
    end

    attr_reader :name, :directive

    def initialize
      @name = :directive
      @directive = "DIRECTIVE"
    end

    def filter_type
      [:filter]
    end

    def default(website_file=nil)
      nil
    end

    def value(website_file)
      get_value(website_file) || default(website_file)
    end

    def get_value(website_file)
      match(website_file.raw_contents)
    end

    def match(contents)
      get_match(contents)
    end

    def get_match(contents)
      m = contents.match(regex)
      m.nil? ? nil : m[1]
    end

    # Returns the contents to replace the directive with as written.
    #
    # @param [WebsiteFile] website_file The page in which the directive appears
    # @param [String, nil] processing_contents The contents of the given WebsiteFile as they are
    #   being transformed by processing.
    # @return [String] What to replace the directive with.
    def replacement(website_file, processing_contents=nil)
      ""
    end

    def regex
      Regexp.new('^\s*' + @directive.to_s + '\(([\w\W]*?)\)')
    end

    def process(website_file, processing_contents)
      m = processing_contents.match(regex)

      while not m.nil?
        repl = replacement(website_file, processing_contents)

        # Remove the next match.
        processing_contents = processing_contents.sub(regex, repl.to_s)

        # Find any others...
        m = processing_contents.match(regex)
      end

      processing_contents
    end
  end
end


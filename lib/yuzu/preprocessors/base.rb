
module Yuzu::PreProcessors
  include Yuzu::Registrar

  # Preprocessors differ from PostProcesors and Filters in that they are allowed to modify the
  # raw_contents of a website_file. e.g. When contents are inserted from other files, they are done
  # so in a manner to create the illusion that those contents were part of the original file.
  class PreProcessor < Register
    @@preprocessors = {}
    def self.registry
      :preprocessors
    end
    def self.preprocessors
      @@preprocessors
    end

    attr_reader :name

    def initialize
      @name = :preprocessor
      @directive = "PREPROCESSOR"
    end

    def value(website_file)
      match(website_file.raw_contents)
    end

    def match(contents)
      m = contents.to_s.match(regex)
      m[1]
    end

    def regex
      Regexp.new('^\s*' + @directive.to_s + '\(([\w\s\.\,\'\"\/\-:]*?)\)')
    end

    # Returns the contents to replace the directive with as written. This will modify the raw
    # contents of the website_file.
    #
    # @param [WebsiteFile] website_file The page in which the directive appears
    # @param [String, nil] new_contents The contents of the given WebsiteFile as they are
    #   being transformed by processing.
    # @return [String] What to replace the directive with.
    def replacement(website_file, new_contents="")
      website_file.raw_contents
    end

    def process(website_file, new_contents)
      replaced = false

      m = new_contents
            .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
            .match(regex)

      while not m.nil?
        repl = replacement(website_file, new_contents)

        # Remove the next match.
        new_contents = new_contents.sub(regex, repl.to_s)
        replaced = true

        # Find any others...
        m = new_contents.match(regex)
      end

      if replaced
        website_file.instance_variable_set(:@raw_contents, new_contents)
      end
    end
  end

end


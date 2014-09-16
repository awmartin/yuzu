require 'helpers/import'

import 'yuzu/filters/base'

module Yuzu::Filters
  class PostTitleRemovedFilter < Filter
    def initialize
      @directive = "POSTTITLEREMOVED"
      @name = :post_title_removed
    end

    def default(website_file)
      ""
    end

    def regex
      nil
    end

    def replacement(website_file, processing_contents=nil)
    end

    def translators
      Yuzu::Translators::Translator.translators
    end

    # Override the processing behavior as the 'regex' function needs to be tailored for the
    # specific file type. Here, we can intercept the processing logic and ask the Translators what
    # the best Regexp is for the given file.
    def process(website_file, processing_contents)
      return processing_contents if not website_file.config.remove_h1_tags

      possible_translators = \
        translators.select {|name, translator| translator.translates?(website_file)}
      return processing_contents if possible_translators.length == 0

      #if possible_translators.nil?
      #  throw "nil 1"
      #elsif possible_translators[0].nil?
      #  throw "nil 2"
      #end

      translator = possible_translators.values[0]

      # Just remove the first one, if we can.
      translator.h1_regex.nil? ? processing_contents : processing_contents.sub(translator.h1_regex, "")
    end
  end
  Filter.register(:post_title_removed => PostTitleRemovedFilter)
end


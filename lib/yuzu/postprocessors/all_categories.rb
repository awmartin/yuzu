require 'helpers/import'

import 'yuzu/core/visitor'
import 'yuzu/postprocessors/base'

module Yuzu::PostProcessors

  class AllCategoriesPostProcessor < PostProcessor
    def initialize
      @name = :all_categories
    end

    def regex
    end

    def default_value(website_file)
      []
    end

    def value(website_file)
      # There should only be one set of categories no matter which WebsiteFile is asked to gather
      # them. So we can cache the value in this singleton.
      @value ||= get_value(website_file)
    end

    def get_value(website_file)
      cats = []
      found_names = []

      v = Yuzu::Core::Visitor.new(proc {|c| c.file? and not c.hidden?})
      v.traverse(website_file.root) do |f|
        # NOTE Because of Ruby's hashing algorithm, we'll get different results calling uniq on an
        # array with objects hashed against a simple string. The comparison doesn't produce truly
        # unique results, and the categories.uniq call isn't accurate or consistent.

        f.categories.each do |cat|
          if not found_names.include?(cat.name) and not cat.name == "uncategorized"
            found_names.push(cat.name)
            cats.push(cat)
          end
        end
      end

      cats.sort
    end
  end
  PostProcessor.register(:all_categories => AllCategoriesPostProcessor)

end


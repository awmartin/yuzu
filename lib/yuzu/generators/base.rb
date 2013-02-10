require 'filters/base'

module Yuzu::Generators
  include Yuzu::Registrar
  include Yuzu::Filters

  # Generators are like filters but they have the ability to produce new files and folders in the
  # website tree.
  class Generator < Filter
    @@generators = {}
    def self.registry
      :generators
    end
    def self.generators
      @@generators
    end

    attr_reader :name, :directive

    def initialize
      @name = :generator
      @directive = "GENERATOR"
    end

    def should_generate?(website_file)
      false
    end

    def visitor_filter
      proc {|c| true}
    end

    # generate!() is called on the first pass by a visitor in the siteroot.
    #
    # @param [WebsiteFile, WebsiteFolder] website_obj The seed page that requires generation.
    def generate!(website_obj)
      # Produce new children and add them to the tree, if necessary.
    end
  end

end




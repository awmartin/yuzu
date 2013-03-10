require 'helpers/import'
import 'yuzu/core/registrar'

module Yuzu::PostProcessors
  include Yuzu::Registrar

  class PostProcessor < Register
    @@postprocessors = {}
    def self.registry
      :postprocessors
    end
    def self.postprocessors
      @@postprocessors
    end

    attr_reader :name

    def initialize
      @name = :postprocessor
    end

    def value(website_file)
      match(website_file.rendered_contents)
    end

    def match(contents)
      contents.to_s.match(regex)
    end

    def regex
      /.*/
    end
  end

end


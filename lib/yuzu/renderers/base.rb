
module Yuzu::Renderers
  include Yuzu::Registrar

  class Renderer < Register
    @@renderers = {}
    def self.registry
      :renderers
    end
    def self.renderers
      @@renderers
    end

    def initialize
    end

    def render(website_file)
      ""
    end
  end

end


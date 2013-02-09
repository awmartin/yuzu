
module Wren
  module Renderers
    include Wren::Registrar

    class Renderer < Register
      def self.registry
        :renderers
      end
      cattr_reader :renderers

      def initialize
      end

      def render(website_file)
        ""
      end

    end

  end
end


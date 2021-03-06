require 'helpers/import'
import 'yuzu/renderers/base'

module Yuzu

  module Renderers
    # Renders the html <title> tag.
    class TitleRenderer < Renderer
      def render(website_file)
        config = website_file.config
        if website_file.root? or website_file.home?
          config.site_name
        else
          "#{website_file.post_title} | #{config.site_name}"
        end
      end
    end
    Renderer.register(:title => TitleRenderer)
  end

end


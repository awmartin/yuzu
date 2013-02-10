
module Yuzu
  module Renderers
    # Renders the html <title> tag
    class TitleRenderer < Renderer
      def render(website_file)
        config = website_file.config
        if website_file.root? or website_file.home?
          return config.site_name
        else
          return "#{website_file.post_title} | #{config.site_name}"
        end
      end
    end
    Renderer.register(:title => TitleRenderer)
  end
end


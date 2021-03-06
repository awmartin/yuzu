require 'helpers/import'
import 'html/base'
import 'yuzu/renderers/base'

module Yuzu::Renderers
  class GalleryRenderer < Renderer
    def template_name
      "_gallery.haml"
    end

    def gallery_template
      @template ||= Yuzu::Core::HamlTemplate.new(template_name)
    end

    def render(website_file)
      if gallery_template.exists?
        gallery_template.render(website_file, {:images => website_file.images})
      else
        Html::Comment.new << "Couldn't find gallery template #{gallery_template.path.absolute}"
      end
    end
  end
  Renderer.register(:gallery => GalleryRenderer)
end


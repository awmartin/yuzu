require 'html/base'

module Wren::PostProcessors
  class ThumbnailsPostProcessor < PostProcessor
    def initialize
      @name = "thumbnails"
    end

    def value(website_file)
      thumbnails = website_file.config.thumbnails
      images = website_file.images
      Thumbnails.new(images, thumbnails.keys)
    end
  end
  PostProcessor.register(:thumbnails => ThumbnailsPostProcessor)


  class Thumbnails
    def initialize(images, thumbnail_sizes)
      image_path = images.empty? ? nil : images[0]

      (class << self; self; end).class_eval do
        thumbnail_sizes.each do |size|
          define_method size do
            begin

              if image_path.nil?
                ""
              else
                ext = File.extname(image_path)
                new_name = image_path.sub(ext, "-#{size}#{ext}")
                Html::Image.new(:src => new_name).to_s
              end
            rescue => e
              puts "Exception in thumbnails"
              puts e.message
            end
          end
        end
      end

    end
  end

end



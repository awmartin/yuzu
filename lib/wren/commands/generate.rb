require 'fileutils'

module Wren::Command

  # Generate handles some cross-media production (e.g. pdf) and handling of the creation of files
  # (e.g. thumbnails).
  class Generate < ConfiglessCommand
    def index
    end

    #def pdf
    #  f = File.open(@args.first, "r")
    #  unless f.nil?
    #    contents = f.readlines.join
    #    updater.render_pdf contents, @args.first
    #    updater.done
    #  else
    #    puts "File load error."
    #  end
    #end

    # TODO: Put this in its own class and integrate with the rest of the app.
    def thumbnails
      path = args.first
      web_image_types = [".png", ".jpg", ".gif"]
      thumbnail_types = @config.thumbnails.keys

      thumbnail_endings = []
      thumbnail_types.each do |type|
        web_image_types.each do |ext|
          thumbnail_endings += ["-#{type}#{ext}"]
        end
      end

      if File.directory?(path)
        # Get all the original images requested.
        all_files = Dir[File.join(path, "**/*")]

        images = all_files.select { |f|
                    web_image_types.include?(File.extname(f))
                  }.reject { |f|
                    f[0].chr == "_" or 
                    f.include?("#{File::SEPARATOR}_") or
                    f.includes_one_of?(thumbnail_endings)
                  }
      else
        # A single image.
        images = [path]
      end

      images.each do |image_path|
        ext = File.extname(image_path)

        # Loop through the configured thumbnail types ("small", "medium", etc.)
        thumbnail_types.each do |thumbnail_type|
          thumbnail_path = image_path.gsub(ext, "-#{thumbnail_type}#{ext}")
          thumbnail_size = @config.thumbnails[thumbnail_type]

          puts `cp #{image_path} #{thumbnail_path}; sips --resampleWidth #{thumbnail_size} #{thumbnail_path}`
        end
      end
    end

    def config
      if not File.exists?("wren.yml")
        FileUtils.copy( "#{File.dirname(__FILE__)}/../templates/wren.yml", "#{Dir.pwd}/config/wren.yml")
        puts "Copied a sample config file into the current folder. Update it with your remote server information."
      else
        puts "Config file wren.yml already exists. Rename or erase it to generate a new one."
      end
    end

    def self.help method
      case method
      when :default
        ""
      when :thumbnails
        "Generates small, medium, and large thumbnail images from a given path. Uses Mac 'sips' command-line tool."
      else
        ""
      end
    end
    
  end
end

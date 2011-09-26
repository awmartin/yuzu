require 'fileutils'

module Wren::Command
  class Generate < Base
    def index
      
    end
    
    def pdf
      f = File.open( @args.first, "r" )
      unless f.nil?
        contents = f.readlines.join
        updater.render_pdf contents, @args.first
        updater.done
      else
        puts "File load error."
      end
    end
    
    # TODO: Put this in its own class and integrate with the rest of the app.
    # Generates small, medium, and large thumbnail images from a given path.
    def thumbnails
      path = args.first
      maxHeight = 500
      web_image_types = [".png", ".jpg", ".gif"]
      
      if File.directory?(path)
        all_files = Dir[File.join(path, "**/*")]
        images = all_files.select {|f| web_image_types.include?(File.extname(f))}
      else
        images = [path]
      end
      
      images.each do |image_path|
        ext = File.extname(image_path)
        
        image_path_small = image_path.gsub(ext, "-small#{ext}")
        image_path_medium = image_path.gsub(ext, "-medium#{ext}")
        image_path_large = image_path.gsub(ext, "-large#{ext}")

        puts `cp #{image_path} #{image_path_small}; sips --resampleWidth 320 #{image_path_small}`
        puts `cp #{image_path} #{image_path_medium}; sips --resampleWidth 640 #{image_path_medium}`
        puts `cp #{image_path} #{image_path_large}; sips --resampleWidth 960 #{image_path_large}`
      end
    end
    
    def config
      if not File.exists?("wren.yml")
        FileUtils.copy( "#{File.dirname(__FILE__)}/../templates/wren.yml", "#{Dir.pwd}/wren.yml")
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

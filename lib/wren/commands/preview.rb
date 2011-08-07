module Wren::Command
  class Preview < Base

    def index
      updater.update_these @args
      updater.done
    end
    
    def all
      updater.update_all
      updater.done
    end
    
    def single
      updater.update_these @args
      updater.done
    end
    
    def changed
      git_diff_output = `git diff --name-only --diff-filter=AMRX`
      changed_files = git_diff_output.split("\n")
      updatable_files = changed_files.reject {|f| File.extname(f).includes_one_of?( @config['extension_blacklist'] )}
      
      puts "Found changes to these files:\n" + updatable_files.join("\n").to_s
      puts
      
      updater.update_these updatable_files
      
      puts "Looking for new images to upload..."
      # Traverse images and upload if new.
      catalog = File.open("images-preview.yml","a+") rescue nil
      unless catalog.nil?
        catalog.rewind
        image_paths = catalog.readlines
        known_images = image_paths.collect {|img| img.strip}
        new_images = updater.upload_new_images known_images
        catalog.puts( new_images.join("\n") )
        catalog.close
      end
      
      updater.done
    end
    
    def resources
      puts `compass compile`
      updater.upload_all_resources
      updater.done
    end
    
    def images
      images = updater.upload_all_images
      
      catalog = File.open("images.yml","w")
      catalog.puts images.join("\n")
      catalog.close
      
      updater.done
    end
    
    def assets
      updater.upload_all_assets
      updater.done
    end
    
    def usage
    end
    
    def help
    
    end
    
    def uploader
      @uploader ||= Uploader.new( 'preview', @config )
    end
    
    def self.help method
      case method
      when :default
        "Updates files in the preview folder."
      when :all
        "Updates all files in the preview folder. A fresh start."
      when :changed
      when :resources
      when :images
      when :assets
      else
      end
    end
  end
end
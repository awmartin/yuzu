module Wren::Command
  class Publish < Base
    
    def initialize(args, config_dict)
      @args = args
      @config_dict = config_dict
      @config = WrenConfig.new(config_dict, config_dict['connection'])
    end
    
    def index
      updater.update_these @args
      updater.done
    end
    
    def all
      updater.update_all
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
      catalog = File.open("_images.yml","a+") rescue nil
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
      updater.upload_all_images
      updater.done
    end
    
    def assets
      updater.upload_all_assets
      updater.done
    end
    
    def self.help method
      case method
      when :default
        "Updates files on the remote server."
      when :all
        "Updates all files on remote server. A fresh start."
      when :changed
      when :resources
      when :images
      when :assets
      else
      end
    end
  end
end
require 'suppressor'

require 'content_handlers'
require 'wren_config'
require 'site_cache'

# Updater holds the state necessary to complete a updates of a single file or of multiple files.
class Updater
  
  # Pass in a fully initialized Uploader object.
  def initialize uploader_obj, wren_config_obj
    return if uploader_obj.nil?
    return if wren_config_obj.nil? or not wren_config_obj.is_a?(WrenConfig)
    
    @uploader = uploader_obj
    @config = wren_config_obj

    @site_cache = SiteCache.new @config

    puts "Updater initialized..."
  end
  
  
  # Recusive loop to rebuild the entire site.
  def update_all
    puts "Updating all..."
    
    @site_cache.cache.each_pair do |path, file_cache|
      update_path path
    end
  end
  
  def update_text
    puts "Updating text files..."
    
    @site_cache.cache.each_pair do |path, file_cache|
      if file_cache.text?
        update_path(path)
      end
    end
  end

  def update_path relative_path
    file_cache = @site_cache.cache[relative_path]
    return if file_cache.nil?

    # TODO: handle SASS updates with `compass compile`
    # Don't update folders that begin with underscores.
    if not file_cache.blacklisted? and not relative_path[0].chr == "_"
      if file_cache.processable?
        puts
        puts "------------------"
        puts "Processing #{relative_path}"

        @uploader.upload file_cache.rendered_path, file_cache.contents
      elsif file_cache.file?
        # This is a resource, asset, or other binary file.
        puts
        puts "------------------"
        puts "Updating #{relative_path}"

        f = File.open file_cache.relative_path, "r"
        @uploader.upload file_cache.rendered_path, f
        f.close
      else
        # Folder
        puts
        puts "Skipping #{relative_path}"
      end
    else
      puts
      puts "Skipping #{relative_path}"
    end
  end
  
  # Takes an array of file extensions and traverses the file structure to upload them. It also collects all the
  # file names into an array and returns it.
  # @param extensions Array of Strings: Extensions for the files to upload raw, without processing of any kind.
  def upload_all_files_of_types extensions=[], exclude_files=[]
    list = []
    @site_cache.cache.each do |path, file_cache|
      if not exclude_files.include? file_cache.relative_path
        if file_cache.extension.includes_one_of? extensions
          update_path path
          list += [path]
        end
      end
    end
    list
  end
  
  def upload_new_images known_images=[]
    return upload_all_files_of_types(@config.image_extensions, known_images)
  end
  
  def upload_all_images
    return upload_all_files_of_types(@config.image_extensions)
  end
  
  def upload_all_assets
    return upload_all_files_of_types(@config.asset_extensions)
  end
  
  def upload_all_resources
    return upload_all_files_of_types(@config.resource_extensions)
  end

  # Update a particular list of files, presented as an array.
  def update_these array_of_files=[]
    puts "Calling Updater#update_these..."
    
    array_of_files.each do |relative_path|
      update_path relative_path
    end
  end  
  
  def done
    @uploader.close unless @uploader.nil?
    @suppressor.close unless @suppressor.nil?
  end
end

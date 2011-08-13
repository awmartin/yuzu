

class WrenConfig
  def initialize config_dict
    @config = config_dict
  end
  
  def processable? local_path=""
    return false if local_path.blank?
    ext = File.extname(local_path.to_s).to_s
    return (ext.includes_one_of?(processable_extensions) and !ext.includes_one_of?(extension_blacklist))
  end
  
  def site_name
    @config['site_name']
  end
  
  def use_strict_index_links
    @config['use_strict_index_links']
  end
  
  # Don't traverse these folders.
  def folder_blacklist
    @config['folder_blacklist']
  end
  
  def no_index_folders
    @config['no_index_folders']
  end
  
  def extension_blacklist
    @config['extension_blacklist']
  end
  
  def processable_extensions
    @config['processable_extensions']
  end
  
  def image_extensions
    @config['image_extensions']
  end
  
  def asset_extensions
    @config['asset_extensions']
  end
  
  def resource_extensions
    @config['resource_extensions']
  end
  
  def template_dir
    @config['template_dir']
  end
  
  def blog_dir
    @config['blog_dir']
  end
  
  def link_root_for_service service
    @config[service]['link_root'].to_s
  end
end
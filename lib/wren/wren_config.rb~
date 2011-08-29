

class WrenConfig
  attr_reader :config_dict
  
  def initialize config_dict
    @config_dict = config_dict
  end
  
  def processable? local_path=""
    return false if local_path.blank?
    ext = File.extname(local_path.to_s).to_s
    return (ext.includes_one_of?(processable_extensions) and !ext.includes_one_of?(extension_blacklist))
  end
  
  def site_name
    @config_dict['site_name']
  end
  
  def use_strict_index_links
    @config_dict['use_strict_index_links']
  end
  
  # Don't traverse these folders.
  def folder_blacklist
    @config_dict['folder_blacklist']
  end
  
  def no_index_folders
    @config_dict['no_index_folders']
  end
  
  def extension_blacklist
    @config_dict['extension_blacklist']
  end
  
  def processable_extensions
    @config_dict['processable_extensions']
  end
  
  def image_extensions
    @config_dict['image_extensions']
  end
  
  def asset_extensions
    @config_dict['asset_extensions']
  end
  
  def resource_extensions
    @config_dict['resource_extensions']
  end
  
  def template_dir
    @config_dict['template_dir']
  end
  
  def blog_dir
    @config_dict['blog_dir']
  end
  
  def link_root_for_service service
    @config_dict[service]['link_root'].to_s
  end
  
  def breadcrumb_omit_current_page
    @config_dict['breadcrumb_omit_current_page']
  end
  
  def breadcrumb_separator
    @config_dict['breadcrumb_separator']
  end
end
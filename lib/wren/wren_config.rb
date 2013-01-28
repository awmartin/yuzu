
class WrenConfig
  attr_reader :config_dict, :service

  def initialize(config_dict, service='preview')
    @config_dict = config_dict
    @service = service
  end

  define_method(:author) { @config_dict.has_key?("author") ? @config_dict['author'] : "" }
  define_method(:remove_h1_tags) {
    @config_dict.has_key?("remove_h1_tags") ? @config_dict['remove_h1_tags'] : false
    }

  def processable?(local_path="")
    return false if local_path.blank?
    ext = File.extname(local_path.to_s).to_s
    return (ext.includes_one_of?(processable_extensions) and !ext.includes_one_of?(extension_blacklist))
  end

  def thumbnails
    @config_dict['thumbnails']
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
    @config_dict.has_key?('blog_dir') ? @config_dict['blog_dir'] : nil
  end
  
  def no_render
    @config_dict.has_key?('no_render') ? @config_dict['no_render'] : []
  end

  def link_root_for_service service
    @config_dict[service]['link_root'].to_s
  end

  def link_root
    link_root_for_service @service
  end

  def domain
    domain_for_service @service
  end

  def domain_for_service service
    @config_dict[service]['domain'].to_s
  end

  def breadcrumb_omit_current_page
    @config_dict['breadcrumb_omit_current_page']
  end

  def breadcrumb_separator
    @config_dict['breadcrumb_separator']
  end

  def possible_indices
    @processable_indices ||= processable_extensions.collect {|e| "index#{e}"}
  end

  def preview?
    return @service == 'preview'
  end

  # Checks to see whether file should be considered hidden. By default, all
  # filenames and folders starting with an underscore are hidden.
  def is_hidden?(path)
    parts = path.split(File::SEPARATOR)
    hidden = parts.collect do |f|
      f[0].chr == "_"
    end
    hidden.any?
  end

  def is_blacklisted?(path)
    #parts = path.split(File::SEPARATOR)
    #blacklisted = parts.collect do |f|
    #  @config.folder_blacklist.include?(f)
    #end
    #blacklisted.any?

    # This is better since it requires the user to specify the exact path,
    # like blog/drafts, instead of just drafts, which may appear elsewhere.
    path.includes_one_of?(folder_blacklist)
  end
end

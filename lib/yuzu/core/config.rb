require 'pathname'
require 'helpers/path'

module Yuzu::Core
  class Config
    include Helpers

    attr_reader :config_dict, :service

    #@@keys_and_defaults = {}

    def initialize(config_dict, service_override=nil)
      @config_dict = config_dict
      @service = service_override || config_dict['connection']

      # Create a method for every top-level key in the configuration dictionary.
      (class << self; self; end).class_eval do
        config_dict.each_pair do |key, value|
          instance_variable = "@#{key}".to_sym

          define_method key do
            if instance_variable_get(instance_variable).nil?
              instance_variable_set(instance_variable, value)
            end
            instance_variable_get(instance_variable)
          end

          define_method "set_#{key}" do |other|
            instance_variable_set(instance_variable, other)
          end

        end
      end
    end

    def pwd
      Path.new
    end

    def processable?(path)
      check_extension(path.extension, processable_extensions)
    end

    def resource?(path)
      check_extension(path.extension, resource_extensions)
    end

    def image?(path)
      check_extension(path.extension, image_extensions)
    end

    def asset?(path)
      check_extension(path.extension, asset_extensions)
    end

    def check_extension(extension, extensions)
      return false if extension_blacklist.include?(extension)
      return extensions.include?(extension)
    end

    def can_index_folder?(path)
      absolute_no_index_paths = (no_index_folders + folder_blacklist + system_folders).collect {|p| Path.new(p)}

      tr = false
      absolute_no_index_paths.each do |folder|
        tr ||= folder.contains?(path)
      end
      not tr
    end

    def system_folders
      ["config", ".git"]
    end

    def link_root_for_service(service)
      @config_dict['services'][service]['link_root'].to_s
    end

    def link_root
      link_root_for_service(@service)
    end

    def linkroot
      link_root
    end

    def domain
      domain_for_service @service
    end

    def domain_for_service service
      @config_dict[service]['domain'].to_s
    end

    def possible_indices
      @processable_indices ||= processable_extensions.collect {|e| "index#{e}"}
    end

    def preview?
      @service == 'preview'
    end

    def stage?
      @service == 'stage'
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
      path.includes_one_of?(folder_blacklist)
    end
  end

end

require 'yaml'
require 'etc'

module Yuzu::Content
  class ProjectNotFound < Exception; end
  class ThemeNotFound < Exception; end
  class SampleContentNotFound < Exception; end
  class ConfigNotFound < Exception; end

  class SampleProject
    def self.registered_projects
      @@registry ||= YAML.load_file(registry_file)
    end

    def self.registry_file
      File.join(resources_folder, "sample_projects.yml")
    end

    def initialize(sample_project_name)
      @name = sample_project_name

      if SampleProject.registered_projects.has_key?(@name)
        @project_info = SampleProject.registered_projects[@name]
      else
        raise ProjectNotFound, "#{@name} is not a known sample project."
      end
    end

    def deliver!
      copy_theme!
      copy_content!
      copy_config!
    end

    def theme_name
      @project_info['theme']
    end

    def sample_content_name
      @project_info['content']
    end

    def copy_theme!
      theme_folder = File.join(SampleProject.theme_folder, theme_name)
      if File.exists?(theme_folder)
        copy_folder_contents!(theme_folder)
      else
        throw ThemeNotFound, "#{theme_name} is not a known theme."
      end
    end

    def copy_content!
      content_folder = File.join(SampleProject.sample_content_folder, sample_content_name)
      if File.exists?(content_folder)
        copy_folder_contents!(content_folder)
      else
        throw SampleContentNotFound, "#{sample_content_name} is not a known set of sample content."
      end
    end

    def copy_config!
      config_folder = File.join(SampleProject.resources_folder, "config")
      copy_folder!(config_folder)
      post_process_config!
    end

    def copy_folder!(folder_name)
      FileUtils.cp_r(folder_name, SampleProject.destination_folder)
    end

    def copy_folder_contents!(folder)
      source = File.join(folder, "*")
      FileUtils.cp_r(Dir[source], SampleProject.destination_folder)
    end

    def post_process_config!
      destination_config = File.join(SampleProject.destination_folder, "config", "yuzu.yml")
      if File.exists?(destination_config)
        user_home_folder = File.expand_path("~")
        username = Etc.getlogin

        config_contents = File.read(destination_config)

        config_contents.gsub!("HOME", user_home_folder)
        config_contents.gsub!("USERNAME", username)
        config_contents.gsub!("PROJECTFOLDER", SampleProject.project_folder_name)

        File.open(destination_config, "w") do |config|
          config.puts(config_contents)
        end

        load_new_config!(destination_config)
      else
        raise ConfigNotFound, "The yuzu.yml file wasn't found in the expected place: #{destination_config}."
      end
    end

    def load_new_config!(destination_config_path)
      @new_config ||= YAML.load_file(destination_config_path)
    end

    def new_config
      if @new_config.nil?
        raise ConfigNotFound, "New config file not found."
      else
        @new_config
      end
    end

    def self.theme_folder
      File.join(resources_folder, "themes")
    end

    def self.sample_content_folder
      File.join(resources_folder, "sample_content")
    end

    def self.resources_folder
      File.join(File.dirname(__FILE__), "..", "..", "..", "resources")
    end

    def self.destination_folder
      Dir.pwd
    end

    def self.project_folder_name
      File.basename(destination_folder)
    end

    def self.exists?(sample_project_name)
      registered_projects.has_key?(sample_project_name)
    end
  end # SampleProject

end

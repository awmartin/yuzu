
module Yuzu::Content
  class ProjectNotFound < Exception; end
  class ThemeNotFound < Exception; end
  class SampleContentNotFound < Exception; end

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

    def copy_theme!
      theme_name = @project_info['theme']
      theme_folder = File.join(SampleProject.theme_folder, theme_name)
      if File.exists?(theme_folder)
        copy_folder_contents!(theme_folder)
      else
        throw ThemeNotFound, "#{theme_name} is not a known theme."
      end
    end

    def copy_content!
      content_name = @project_info['content']
      content_folder = File.join(SampleProject.sample_content_folder, content_name)
      if File.exists?(content_folder)
        copy_folder_contents!(content_folder)
      else
        throw SampleContentNotFound, "#{content_name} is not a known set of sample content."
      end
    end

    def copy_config!
      config_folder = File.join(SampleProject.resources_folder, "config")
      copy_folder!(config_folder)
    end

    def copy_folder!(folder_name)
      FileUtils.cp_r(folder_name, SampleProject.destination_folder)
    end

    def copy_folder_contents!(folder)
      source = File.join(folder, "*")
      FileUtils.cp_r(Dir[source], SampleProject.destination_folder)
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

    def self.exists?(sample_project_name)
      registered_projects.has_key?(sample_project_name)
    end
  end # SampleProject

end

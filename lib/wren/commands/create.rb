module Wren::Command
  class Create < Base
    def index
      puts `compass create . --using blueprint --syntax sass`
      puts `mkdir _templates`
      destination_dir = Dir.pwd
      Dir["#{File.dirname(__FILE__)}/../templates/*"].each do |template|
        file = File.basename(template)
        
        puts "Copying #{file}..."
        
        if file[0].chr == "_"
          FileUtils.copy( "#{template}", "#{destination_dir}/_templates/#{file}")
        else
          FileUtils.copy( "#{template}", "#{destination_dir}/#{file}")
        end
        
      end
      puts
      puts "Remember to edit wren.yml to set your site settings, preview path, and remote host."
    end
    
    def self.help method
      case method
      when :default
        "Create a new website project in the current directory. This creates a new sass project then generates a new configuration file."
      else
      end
    end
  end
end

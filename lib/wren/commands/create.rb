module Wren::Command
  class Create < Base
    def index
      puts `compass create . --using blueprint --syntax sass`
      Dir["#{File.dirname(__FILE__)}/../templates/*"].each do |template|
        file = File.basename(template)
        puts "Copying #{file}..."
        FileUtils.copy( "#{template}", "#{Dir.pwd}/#{file}")
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

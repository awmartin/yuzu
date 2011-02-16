require 'fileutils'

module Wren::Command
  class Generate < Base
    def index
    end
    
    def pdf
    end
    
    def config
      if not File.exists?("wren.yml")
        FileUtils.copy( "#{File.dirname(__FILE__)}/../templates/wren.yml", "#{Dir.pwd}/wren.yml")
        puts "Copied a sample config file into the current folder. Update it with your remote server information."
      else
        puts "Config file wren.yml already exists. Rename or erase it to generate a new one."
      end
    end
    
  end
end
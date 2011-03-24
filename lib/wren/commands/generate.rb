require 'fileutils'

module Wren::Command
  class Generate < Base
    def index
    end
    
    def pdf
      f = File.open( @args.first, "r" )
      unless f.nil?
        contents = f.readlines.join
        updater.render_pdf contents, @args.first
        updater.done
      else
        puts "File load error."
      end
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
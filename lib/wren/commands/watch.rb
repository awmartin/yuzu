require 'fssm'

def rebuild_site(file_path)
  puts ">>> Change Detected to: #{file_path} <<<"
  
  IO.popen("wren preview #{file_path}") do |io|
    print( io.readpartial(512) ) until io.eof?
  end
  
  puts '>>> Update Complete <<<'
end

module Wren::Command
  class Watch < Base
    # Method to start the watcher.
    def index
      
      puts ">>> Watching for Changes <<<"
      FSSM.monitor("#{Dir.pwd}", '**/*') do
        update {|base, relative| rebuild_site(relative)}
        delete {|base, relative| rebuild_site(relative)}
        create {|base, relative| rebuild_site(relative)}
      end

    end
    
    def self.help method
      case method
      when :default
        "Watches the current directory for changes."
      else
      end
    end
  end
end
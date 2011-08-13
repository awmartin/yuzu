require 'fssm'

def rebuild_site(base, relative_path)
  puts ">>> Change Detected to: #{relative_path} <<<"

  IO.popen("wren preview:single #{relative_path}") do |io|
    print( io.readpartial(512) ) until io.eof?
  end
  
  puts '>>> Update Complete <<<'
end

module Wren::Command
  class Watch < Base
    # Method to start the watcher.
    def index
      
      puts ">>> Wren is watching for changes <<<"
      FSSM.monitor("#{Dir.pwd}", '**/*') do
        update {|base, relative| rebuild_site(base, relative)}
        delete {|base, relative| rebuild_site(base, relative)}
        create {|base, relative| rebuild_site(base, relative)}
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
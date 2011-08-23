require 'fssm'

def rebuild_site(base, relative_path, config)
  puts ">>> Change Detected to: #{relative_path} <<<"

  if File.directory?(relative_path)
    if relative_path.includes_one_of?(config.folder_blacklist)
      puts ">>> Blacklisted folder found. No update."
      return
    elsif relative_path.include?(config.template_dir)
      puts ">>> Change in a template found. No update (yet)."
      return
    end
  else
    file_ext = File.extname(relative_path)
    #if relative_path.includes_one_of?(config.folder_blacklist)
    #  puts ">>> Blacklisted folder found. No update."
    #  return
    #els
    if file_ext.includes_one_of?(config.extension_blacklist)
      puts ">>> Blacklisted extension found. No update."
      return
    elsif relative_path.include?(config.template_dir)
      puts ">>> Change in a template found. No update (yet)."
      return
    end
  end

  IO.popen("wren preview #{relative_path}") do |io|
    print( io.readpartial(512) ) until io.eof?
  end

  puts '>>> Update Complete <<<'
end


module Wren::Command
  class Watch < Base
    # Method to start the watcher.
    def index
      
      puts ">>> Wren is watching for changes <<<"
      
      # The block below doesn't have the current Watch object in its scope,
      # so we can't pass in @config directly. Pass it into the *args parameter
      # and the hash becomes part of the @options instance variable in the
      # FSSM implementation. Then unpack it and pass the WrenConfig(@config)
      # to the rebuild_site method.
      FSSM.monitor("#{Dir.pwd}", '**/*', :config => @config) do
        update {|base, relative| rebuild_site(base, relative, @options[:config])}
        delete {|base, relative| rebuild_site(base, relative, @options[:config])}
        create {|base, relative| rebuild_site(base, relative, @options[:config])}
      end

    end

    
    def self.help method
      case method
      when :default
        "Watches the current directory for changes and automatically updates the preview of changed files."
      else
      end
    end
  end
end

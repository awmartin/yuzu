require 'fileutils'
require 'uploader'
require 'updater'
require 'wren_config'

module Wren::Command
  class Base
    include Wren::Helpers

    attr_accessor :args
    
    def initialize(args, config_dict)
      @args = args
      @config_dict = config_dict
      # Assume preview for safety. Subclass can override.
      @config = WrenConfig.new(config_dict, 'preview')
    end
    
    def shell(cmd)
      FileUtils.cd(Dir.pwd) {|d| return `#{cmd}`}
    end
    
    def updater
      @updater ||= Updater.new( uploader, @config )
    end
    
    def uploader
      @uploader ||= Uploader.new( @config_dict['connection'], @config_dict )
    end
    
    def self.help method
    end
  end
end

require 'fileutils'
require 'uploader'
require 'updater'

module Wren::Command
  class Base
    include Wren::Helpers

    attr_accessor :args
    
    def initialize(args, config)
      @args = args
      @config = config
    end
    
    def shell(cmd)
			FileUtils.cd(Dir.pwd) {|d| return `#{cmd}`}
		end
		
		def updater
      @updater ||= Updater.new( uploader, @config )
	  end
	  
	  def uploader
      @uploader ||= Uploader.new( @config['connection'], @config )
    end
    
    def self.help method
    end
  end
end

require 'fileutils'

require 'uploader/base'

require 'core/updater'
require 'core/config'

require 'helpers/string'
require 'helpers/object'

module Wren::Command

  # The Base class for all commands provides methods for coordinating the Updater, which manages the
  # files to be updated and the actual update commands, and the Uploader, which takes care of
  # turning update operations into service calls via FTP, S3, etc.
  class Base
    include Uploader

    attr_reader :args

    def initialize(args, config)
      @args = args
      @config = config
    end

    def self.shell(cmd)
      FileUtils.cd(Dir.pwd) {|d| return `#{cmd}`}
    end

    def updater
      @updater ||= Wren::Core::Updater.new(uploader, @config)
    end

    def uploader
      @uploader ||= UploadManager.new(uploader_config, self.class.service_override)
    end

    def uploader_config
      config_hash = @config.services.merge({:connection => @config.connection})
      Uploader::UploaderConfig.new(config_hash)
    end

    # This method enables a command to override the configuration's selected publication service.
    # Some commands work only locally, such as preview, or don't have a publication method involved.
    def self.service_override
      nil
    end

    def self.help(method)
    end

    def self.requires_config?
      true
    end
  end


  class ConfiglessCommand
    def initialize(args)
      @args = args
    end

    def self.help(method)
    end

    def self.requires_config?
      false
    end
  end


  class PublicationCommand < Base
    include Uploader

    def index
      updater.update_these(@args)
      updater.done
    end

    def all
      updater.update_all
      updater.done
    end

    def text
      updater.update_text
      updater.done
    end

    def resources
      puts `compass compile`
      updater.upload_all_resources
      updater.done
    end

    def css
      puts `compass compile`
      updater.upload_all_css
      updater.done
    end

    def images
      images = updater.upload_all_images

      catalog = File.open("_images.yml","w")
      catalog.puts(images.join("\n"))
      catalog.close

      updater.done
    end

    def assets
      updater.upload_all_assets
      updater.done
    end

    def changed
    #  git_diff_output = `git diff --name-only --diff-filter=AMRX`
    #  changed_files = git_diff_output.split("\n")
    #  updatable_files = changed_files.reject {|f| File.extname(f).includes_one_of?( @config['extension_blacklist'] )}

    #  puts "Found changes to these files:\n" + updatable_files.join("\n").to_s
    #  puts

    #  updater.update_these(updatable_files)

    #  puts "Looking for new images to upload..."

    #  # Traverse images and upload if new.
    #  catalog = File.open("images-preview.yml","a+") rescue nil

    #  unless catalog.nil?
    #    catalog.rewind
    #    image_paths = catalog.readlines
    #    known_images = image_paths.collect {|img| img.strip}
    #    new_images = updater.upload_new_images known_images
    #    catalog.puts(new_images.join("\n"))
    #    catalog.close
    #  end

    #  updater.done
    end
  end

end

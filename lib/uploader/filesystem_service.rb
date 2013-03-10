require 'fileutils'

require 'helpers/import'
import 'uploader/base'
import 'uploader/service'


module Uploader
  GREEN = "\033[32m"
  ENDC = "\033[0m"

  class FileSystemService < Service
    def connect!
    end

    def upload(remote_path, contents)
      raise UploadArgumentError if not remote_path.is_a?(Path)

      contents_to_upload, binmode = get_upload_contents(contents)

      copy_contents_to_file_system(remote_path, contents_to_upload, binmode)
    end

    def get_upload_contents(contents)
      binmode = false
      if contents.is_a?(File)
        contents_to_upload = contents.read
        binmode = true

      elsif contents.is_a?(String)
        contents_to_upload = contents

      else
        raise UnrecognizedContentType
      end

      return contents_to_upload, binmode
    end

    def copy_contents_to_file_system(remote_path, contents, binary=true)
      destination = Path.new(@config.destination) + remote_path.relative

      if @config.verbose?
        $stderr.puts %Q{Copying #{GREEN}#{remote_path}#{ENDC} to the file system
      --> #{destination}} 
      else
        $stderr.print "."
      end

      begin
        f = File.open(destination.absolute, "w+")

      rescue => detail
        $stderr.puts detail.message if @config.verbose?
        $stderr.puts "Attempting to create the path." if @config.verbose?

        # Assume the directories leading to the file don't exist. Create them.
        FileUtils::mkdir_p(destination.dirname)

        f = File.open(destination.absolute, "w+")
      end

      unless f.nil?
        f.syswrite(contents)
        f.close
        $stderr.puts "Done with #{destination.relative}." if @config.verbose?
      end
    end
  end

  Service.register(:filesystem => FileSystemService)
  Service.register(:stage => FileSystemService)
  Service.register(:preview => FileSystemService)
end


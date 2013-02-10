require 'fileutils'
require 'uploader/service'


module Uploader
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

      $stderr.puts "Copying #{GREEN}#{remote_path}#{ENDC} to the file system\n    --> #{destination}"

      begin
        f = File.open(destination.absolute, "w+")

      rescue => detail
        $stderr.puts detail.message
        $stderr.puts "Attempting to create the path."

        # Assume the directories leading to the file don't exist. Create them.
        FileUtils::mkdir_p(destination.dirname)

        f = File.open(destination.absolute, "w+")
      end

      unless f.nil?
        f.syswrite(contents)
        f.close
        $stderr.puts "Done with #{destination.relative}."
      end
    end
  end

  Service.register(:filesystem => FileSystemService)
  Service.register(:stage => FileSystemService)
  Service.register(:preview => FileSystemService)
end


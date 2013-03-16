require 'net/ftp'
require 'stringio'

require 'helpers/import'
import 'uploader/base'
import 'uploader/service'

module Uploader
  class FtpService < Service

    def connect!
      $stderr.puts "Opening a persistent FTP connection to #{@config.host}..." + (@config.dry_run? ? " (dry run)" : "")

      if not @config.dry_run?
        @ftp = Net::FTP.new
        @ftp.passive = true
        @ftp.connect(@config.host)
        @ftp.login(@config.username, @config.password)
      end
    rescue => e
      $strerr.puts "Something went wrong with the FTP login."
      @stderr.puts e.message
    end

    def close!
      @ftp.close if not @config.dry_run?
    end

    def initialized?
      not @ftp.nil? or @config.dry_run?
    end

    def upload(remote_path, contents)
      raise UploadArgumentError if not remote_path.is_a?(Path)

      if contents.is_a?(File)
        upload_via_ftp(remote_path, contents)

      elsif contents.is_a?(String)
        upload_contents_via_ftp(remote_path, contents)

      else
        raise UnrecognizedContentType

      end
    end

    def upload_contents_via_ftp(remote_path, contents)
      file = StringIO.new(contents)
      upload_via_ftp(remote_path, file, false)
    end

    def upload_via_ftp(remote_path, file, binary=true)
      server_path = Path.new(@config.remote_root_path) + remote_path.relative

      $stderr.puts "Attempting to upload via FTP: #{remote_path}" + (@config.dry_run? ? " (dry run)" : "")

      begin
        attempt_upload!(server_path, file, binary)
      rescue => e
        $stderr.puts "FTP Error"
        $stderr.puts e.message + " (#{e.class})"

        create_remote_folder!(server_path)
        attempt_upload!(server_path, file, binary)
      end
    end

    def attempt_upload!(server_path, file, binary)
      $stderr.puts "      --> Path on server: #{server_path}"

      if binary
        upload_binary(server_path, file)
      else
        upload_nonbinary(server_path, file)
      end
    end

    def upload_binary(server_path, file)
      if not @config.dry_run?
        file.binmode
        @ftp.storbinary("STOR #{server_path}", file, Net::FTP::DEFAULT_BLOCKSIZE)
      else
        $stderr.puts "      --> Uploading #{server_path} (dry run)"
      end
    end

    def upload_nonbinary(server_path, file)
      if not @config.dry_run?
        @ftp.storlines("STOR #{server_path}", file)
      else
        $stderr.puts "      --> Uploading #{server_path} (dry run)"
      end
    end

    def create_remote_folder!(server_path)
      return if @config.dry_run?

      server_path.descend do |path|
        begin
          @ftp.mkdir(path)
        rescue Net::FTPPermError
          $stderr.puts "Remote folder already exists."
        rescue
          # Ok.
        end
      end
    end

  end

  Service.register(:ftp => FtpService)
end



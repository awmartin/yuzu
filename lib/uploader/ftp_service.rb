require 'net/ftp'
require 'stringio'

module Uploader
  class FtpService < Service

    def connect!
      $stderr.puts "Opening a persistent FTP connection to #{@config.host}..."

      @ftp = Net::FTP.new
      @ftp.passive = true
      @ftp.connect(@config.host)
      @ftp.login(@config.username, @config.password)
    rescue
      $strerr.puts "Something went wrong with the FTP login."
    end

    def close!
      @ftp.close
    end

    def initialized?
      not @ftp.nil?
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
      server_path = Path.new(@config.remote_root_path) + remote_path

      $stderr.puts "Opening an FTP connection for #{remote_path}"

      begin
        attempt_upload!(server_path, file, binary)
      rescue => e
        $stderr.puts "FTP Error"
        $stderr.puts e.message

        create_remote_folder!(server_path)
        attempt_upload!(server_path, file, binary)
      end
    end

    def attempt_upload!(server_path, file, binary)
      if binary
        file.binmode
        @ftp.storbinary("STOR #{server_path}", file, Net::FTP::DEFAULT_BLOCKSIZE)
      else
        @ftp.storlines("STOR #{server_path}", file)
      end
    end

    def create_remote_folder!(server_path)
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



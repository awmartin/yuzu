require 'helpers/import'

import 'helpers/path'
import 'helpers/system_checks'


module Uploader
  class UnrecognizedContentType < Exception; end
  class ServiceNotConnected < Exception; end
  class UploadArgumentError < Exception; end

  class Service
    include Helpers

    def initialize(config)
      @config = config
    end

    # Called to connect to remote services like FTP and S3.
    def connect!
    end

    # Perform the upload operation to this service.
    #
    # @param [Path] remote_path The relative path to upload. This is prefixed by "remote_root_path"
    #   set in the uploader Config. You can set remote_root_path to "" if you want complete control
    #   over the path.
    # @param [File, String] contents The contents to upload into the remote file
    #   destination.
    # @return nothing
    def upload(remote_path, contents)
    end

    # Closes the service connection, if required.
    def close!
    end

    def initialized?
      false
    end

    @@services = {}

    def self.services
      @@services
    end

    # Returns whether this service appears in the Service class's registry.
    def self.is_registered?(service)
      @@services.keys.include?(service)
    end

    # Registers the Service in the registry, so clients of the service can access it by name.
    def self.register(kwds={})
      @@services.update(kwds)
    end
  end

end

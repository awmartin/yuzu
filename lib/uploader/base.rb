require 'helpers/import'

# Require service.rb first.
import 'uploader/service'
import 'uploader/suppressor'
import 'uploader/config'

Dir["#{File.dirname(__FILE__)}/*"].each do |service|
  import service if service.include?("_service")
end


module Uploader
  class UnrecognizedService < Exception; end

  class UploadManager

    def initialize(config, service_override=nil)
      @config = config   # UploaderConfig
      @service_override = service_override
      @suppressor = Suppressor.new

      set_service!
      connect!
    end

    def set_service!
      service_name, service_class = get_service
      service_config_hash = @config.send(service_name).merge({:verbose? => @config.verbose?})

      @service = service_class.new(UploaderConfig.new(service_config_hash))
    end

    def get_service
      service_key = (@service_override || @config.connection).to_sym

      if Service.is_registered?(service_key)
        $stderr.puts "Using service #{service_key}" if @config.verbose?

        return service_key, Service.services[service_key]
      else
        raise UnrecognizedService
      end
    end

    def connect!
      @service.connect!
    end

    def upload(remote_path, contents)
      @service.upload(remote_path, contents)
    end

    def close!
      @service.close!
      @suppressor.close!
    end
  end

end


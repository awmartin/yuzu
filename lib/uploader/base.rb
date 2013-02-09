require 'uploader/service.rb'

core_files = ["base.rb", "service.rb"]
Dir["#{File.dirname(__FILE__)}/*"].each do |service|
  if not core_files.include?(File.basename(service))
    require service
  end
end

BOLD = "\033[1m"
PURPLE = "\033[95m"
BLUE = "\033[94m"
GREEN = "\033[32m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RED = "\033[91m"
WHITE = "\033[37m"
ENDC = "\033[0m"


module Uploader
  class UnrecognizedService < Exception; end

  class UploadManager

    def initialize(config, service_override=nil)
      @config = config
      @service_override = service_override
      @suppressor = Suppressor.new

      set_service!
      connect!
    end

    def set_service!
      service_name, service_class = get_service
      service_config_hash = @config.send(service_name)

      @service = service_class.new(UploaderConfig.new(service_config_hash))
    end

    def get_service
      service_key = (@service_override || @config.connection).to_sym

      if Service.is_registered?(service_key)
        $stderr.puts "Using service #{service_key}"
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

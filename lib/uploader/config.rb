
module Uploader

  class UploaderConfig
    def initialize(config_hash)
      @config_hash = config_hash

      (class << self; self; end).class_eval do
        config_hash.each_pair do |key, value|
          define_method(key) do
            value
          end
        end
      end
    end
  end

end


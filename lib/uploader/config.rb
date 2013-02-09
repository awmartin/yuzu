
module Uploader

  class UploaderConfig
    def initialize(config_dict)
      @config_dict = config_dict

      (class << self; self; end).class_eval do
        config_dict.each_pair do |key, value|
          define_method(key) do
            value
          end
        end
      end

    end
  end

end


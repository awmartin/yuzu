
module Yuzu::Command

  # Preview enables a publication endpoint that always publishes to the local filesystem such as a
  # web server folder.
  class Preview < PublicationCommand

    def usage
    end

    def help
    end

    def self.service_override
      "preview"
    end

    def self.help(method)
      case method
      when :default
        "Updates files in the preview folder."
      when :all
        "Updates all files in the preview folder. A fresh start."
      when :changed

      when :resources

      when :images

      when :assets

      else

      end
    end
  end

end


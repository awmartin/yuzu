
module Yuzu::Command
  
  # Publish is the primary mechanism to upload files to a remote server such as via FTP or S3.
  class Publish < PublicationCommand

    def self.help method
      case method
      when :index
%Q{Updates files and publishes to the current remote service.

Can be used in the following forms:

publish [filenames]
publish:all
publish:images
publish:resources
publish:assets
}
      when :all
        "Publishes all files to the remote server."
      when :changed
      when :resources
      when :images
      when :assets
      else
      end
    end
  end
end

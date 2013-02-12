
module Yuzu::Command
  
  # Publish is the primary mechanism to upload files to a remote server such as via FTP or S3.
  class Publish < PublicationCommand

    def self.help method
      case method
      when :index
%Q{Updates files and publishes to the current remote service.

Can be used in the following forms:

publish                           # Alias for publish:all below.
publish [filenames]               # Publish just the files listed to the remote server.
publish:all                       # Publish and upload all files.
publish:text                      # Only update the processable content files.
publish:css                       # Regenerates the css files and publishes them.
publish:images                    # Upload all the images.
publish:images [files]            # Upload the images given.
publish:resources                 # Upload all resources like CSS and Javascript files.
publish:assets                    # Upload all assets (like PDFs and other downloadables). 
}

      when :all
        "Publishes and uploads all files to the remote server."

      when :resources
        "Publish all resources like CSS and Javascript files."

      when :images
        "Upload all the images or the ones given after the command."

      when :assets
        "Upload all file assets (usually PDF files and other download archives.)"

      else
        "No help available for #{method}."

      end
    end
  end
end

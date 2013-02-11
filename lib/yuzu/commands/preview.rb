
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
      when :index
%Q{Updates files in the preview folder.

preview [filenames]               # Update the preview with the files listed.
preview:all                       # Update all the files in the preview.
preview:text                      # Only update the processable content files.
preview:css                       # Regenerates the css files and copies them
                                    to the preview.
preview:images                    # Copy all the images into the preview folder.
preview:resources                 # Copy all the resources, like css and js
                                    files, into the preview folder.
preview:assets                    # Copy all images and other assets (like pdfs
                                    and other downloadables) into the preview 
                                    folder.
}
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


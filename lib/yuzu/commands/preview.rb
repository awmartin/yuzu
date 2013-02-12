
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

preview                           # Alias for preview:all below.
preview [filenames]               # Update the preview with the files listed.
preview:all                       # Update all the files in the preview.
preview:text                      # Only update the processable content files.
preview:css                       # Regenerates the css files and copies them
                                    to the preview.
preview:images                    # Copy all the images into the preview folder.
preview:images [files]            # Copy the images listed into the preview folder.
preview:resources                 # Copy all the resources, like CSS and JS
                                    files, into the preview folder.
preview:assets                    # Copy all images and other assets (like PDFs and
                                    other downloadables) into the preview folder.
}

      when :all
        "Updates all files in the preview folder."

      when :resources
        "Copy all the resources, like CSS and JS files, into the preview folder."

      when :images
        "Copy all images into the preview folder."

      when :assets
        %Q{Copy all images and other assets, usually PDF files and other archives, 
into the preview folder.}

      else
        "No help available for #{method}."

      end
    end
  end

end


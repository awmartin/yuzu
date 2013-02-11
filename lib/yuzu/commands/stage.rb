
module Yuzu::Command

  # Stage is used as a third mechanism to render the webpage under production settings, but still to
  # a local file system. The scenario may be that the website must be published with a different
  # mechanism than what is automated, so this enables someone to render with the appropriate
  # linkroot for the final production destination.
  class Stage < PublicationCommand

    def usage
    end

    def help
    end

    def self.service_override
      "stage"
    end

    def self.help method
      case method
      when :index
%Q{Updates files in the staging folder.

Can be used in the following forms:

stage                           # Alias for stage:text below.
stage [filenames]               # Update the local staging folder with the files listed.
stage:all                       # Update all the files in the staging folder.
stage:text                      # Only update the processable content files.
stage:css                       # Regenerates the CSS files and copies them
                                  to the staging folder.
stage:images                    # Copy all the images into the staging folder.
stage:images [files]            # Copy the images listed into the staging folder.
stage:resources                 # Copy all the resources, like CSS and JS
                                  files, into the staging folder.
stage:assets                    # Copy all images and other assets (like PDFs and
                                  other downloadables) into the staging folder.
}

      when :all
        "Updates all files in the staging folder."

      when :resources
        "Copy all the resources, like CSS and JS files, into the staging folder."

      when :images
        "Copy all images into the preview folder."

      when :assets
        %Q{Copy all images and other assets, usually PDF files and other archives, 
into the staging folder.}

      else
        "No help available for #{method}."

      end
    end
  end

end


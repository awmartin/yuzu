
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

stage [filenames]
stage:all
stage:images
stage:resources
stage:assets
}
      when :all
        "Updates all files in the staging folder. A fresh start."
      when :changed

      when :resources

      when :images

      when :assets

      else

      end
    end
  end

end


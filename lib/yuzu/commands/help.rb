module Yuzu::Command

  class Help < ConfiglessCommand
    def initialize(args)
      @args = args
    end

    def index
      if @args.first.nil?
        puts <<-eos
This is yuzu, a blog-aware, static-website generator and publisher that converts a folder
structure with text files and images into an HTML5 website.

-------
Available Commands

help                              # Show this help page.
help [command]                    # Help about the particular command.

preview [filenames]               # Update the preview with the files listed.
preview:all                       # Update all the files in the preview.
preview:text                      # Only update the processable content files.
preview:images                    # Copy all the images into the preview folder.
preview:resources                 # Copy all the resources, like css and js
                                    files, into the preview folder.
preview:assets                    # Copy all images and other assets (like pdfs
                                    and other downloadables) into the preview 
                                    folder.
preview:css                       # Regenerates the css files and copies them
                                    to the preview.

stage [filenames]
stage:all

publish [filenames]
publish:all
publish:images
publish:resources
publish:assets

create                            # Creates a new yuzu project in the current 
                                    folder, including a sass and config file.
create:post "[title]"             # Creates a new blog post in blog_dir, as 
                                    YYYY-MM-DD-title-string.haml

generate:config                   # Generates a blank configuration file in 
                                    the current folder.
generate:thumbnails [file/folder] # Generates small, medium, and large versions 
                                    of the image given or all the images in the
                                    given folder
generate:pdf [filename]           # Generates a pdf for the given file.

watch                             # Starts the auto-updater, watching for
                                    changes and automatically updating the 
                                    preview

-------
External Commands

git commit

The third form, git commit, requires the file tree to be tracked by a git
repository. There is an included post-commit hook script that updates the
files changed in the last commit and all their dependants. Note: This git
repo should be set to ignore binary assets like images and pdfs.

      eos
      else
        command_class, method = Yuzu::Command.parse(@args.first)
        puts command_class.help(method)
      end
    end
  end

end


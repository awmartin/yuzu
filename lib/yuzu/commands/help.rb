module Yuzu::Command
  HELP_MESSAGE = %Q{
This is yuzu, a blog-aware, static-website generator and publisher that converts a folder
structure with text files and images into an HTML5 website.

Typical Usage

    yuzu [command] [options] [files]

Available Commands

help                        # Show this help page.
help [command]              # Help about the particular command.

create                      # Creates a new yuzu project in the current folder.

preview                     # Updates files in the preview folder.
publish                     # Publishes files to the currently selected remote server.
stage                       # Updates files in the staging folder.

generate                    # Generate new content like posts and thumbnails.
}

  class Help < ConfiglessCommand
    def initialize(args)
      @args = args
    end

    def index
      if @args.first.nil?
        puts HELP_MESSAGE
        puts ArgParser
      else
        command_class, method = Yuzu::Command.parse(@args.first)
        puts command_class.help(method)
      end
    end
  end

end



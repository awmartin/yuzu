require 'ostruct'
require 'optparse'
require 'helpers/import'

import 'yuzu/version'

module Yuzu::Command
  HELP_MESSAGE = %Q{
This is yuzu, a blog-aware, static-website generator and publisher that converts
a folder of text files and images into an HTML5 website.

Typical Usage

  yuzu [command] [options] [files]

Available Commands

  help                  # Show this help page.
  help [command]        # Help about the particular command.
  create                # Creates a new yuzu project in the current folder.
  preview               # Updates files in the preview folder.
  publish               # Publishes files to the currently selected remote server.
  stage                 # Updates files in the staging folder.
  generate              # Generate new content like posts and thumbnails.
}

  class ArgParser
    def self.parse(args)
      options = OpenStruct.new
      options.output = :quiet    # :verbose, :debug
      options.dry_run = false

      option_parser = \
      OptionParser.new do |opts|
        opts.banner = ""

        opts.separator "Options"
        opts.separator ""

        opts.on("--verbose", "Run showing verbose output.") do
          options.output = :verbose
        end

        opts.on("-n", "--dry-run", "Execute the command but don't actually copy or publish files.") do
          options.dry_run = true
        end

        opts.on_tail("-h", "--help", "Show this help message.") do
          puts HELP_MESSAGE
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Show version.") do
          puts Yuzu::Version::STRING
          exit
        end
      end

      option_parser.parse!(args)
      options

    end # End self.parse
  end # End ArgParser

end


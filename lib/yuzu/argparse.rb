require 'ostruct'
require 'optparse'
require 'version'

module Yuzu::Command

  class ArgParser
    def self.parse(args)
      options = OpenStruct.new
      options.output = :quiet    # :verbose, :debug

      option_parser = \
      OptionParser.new do |opts|
        opts.banner = "Usage: yuzu [command] [options]"

        opts.separator ""
        opts.separator "Options"

        opts.on("--verbose", "Run showing verbose output.") do
          options.output = :verbose
        end

        opts.on_tail("-h", "--help", "Show this help message") do
          puts Yuzu::Command::HELP_MESSAGE
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Show version") do
          puts Yuzu::VERSION_STRING
          exit
        end
      end

      option_parser.parse!(args)
      options

    end # End self.parse
  end # End ArgParser

end


module Yuzu::Command

  class Help < ConfiglessCommand
    def initialize(args)
      @args = args
    end

    def index
      if @args.first.nil?
        puts ArgParser.parse(["--help"])
      else
        command_class, method = Yuzu::Command.parse(@args.first)
        puts command_class.help(method)
      end
    end
  end

end



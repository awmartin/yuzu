require 'helpers'
require 'commands/base'
require 'yaml'

Dir["#{File.dirname(__FILE__)}/commands/*"].each { |c| require c }

module Wren
  module Command
    class InvalidCommand < RuntimeError; end
    class CommandFailed  < RuntimeError; end
    
    class << self
      def run(command, args)
        config = {}
        if command.include?("publish") or command.include?("preview")
          config = YAML.load_file(Dir.pwd + '/wren.yml') rescue nil
        end
        if config.nil?
          puts "Please run this from the directory with your configuration file (wren.yml), typically your root project folder."
          Process.exit!(true)
        end
        run_internal(command, args.dup, config.dup)
      end
      
      def run_internal(command, args, config)
        klass, method = parse(command)
        runner = klass.new(args, config)
        raise InvalidCommand unless runner.respond_to?(method)
        runner.send(method)
      end
      
      def parse(command)
        parts = command.split(':')
        case parts.size
          when 1
            begin
              return eval("Wren::Command::#{command.capitalize}"), :index
            rescue NameError, NoMethodError
              return Wren::Command::App, command
            end
          when 2
            begin
              return Wren::Command.const_get(parts[0].capitalize), parts[1]
            rescue NameError
              raise InvalidCommand
            end
          else
            raise InvalidCommand
        end
      end
    end
  end
end
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
        if command == "help"
          run_internal("help", [], nil)
          return
        end
        
        config_path = File.join(Dir.pwd, "wren.yml")
        
        if not File.exists?(config_path) and command != "create"
          puts "Please run this from the directory with your configuration file (wren.yml), typically your root project folder."
          Process.exit!(true)
        end
        
        config = {}
        begin
         if command.include?("publish") or command.include?("preview") or command.include?("create:post") or command.include?("watch")
            config = YAML.load_file(config_path)
          end
        rescue => exception
          puts "Error in parsing wren.yaml"
          puts exception.message
          puts exception.description
          config = nil
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

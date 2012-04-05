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
        
        # TODO: Find a better way to distinguish commands that require a config.
        if not File.exists?(config_path) and command != "create"
          puts "Please run this from the directory with your configuration \
file (wren.yml), typically your root project folder. Or use 'create' to \
make a new project."
          Process.exit!(true)
        end
        
        config_dict = {}
        begin
          load_config_on = ["publish", "preview", "create:post", "watch", "stage", "generate:thumbnails"]
          
          if command.includes_one_of?(load_config_on)
            config_dict = YAML.load_file(config_path)
          end
          
        rescue => exception
          puts "Error in parsing wren.yaml"
          puts exception.message
          puts exception.description
          config_dict = nil
          Process.exit!(true)
        end
        
        # if config_dict.nil?
        #   puts "Please run this from the directory with your configuration file (wren.yml), typically your root project folder."
        #   Process.exit!(true)
        # end
        process_options(args)
        
        run_internal(command, args.dup, config_dict.dup)
      end
      
      def process_options args
        if args.include?("--ignore"):
          @folders_to_ignore = []
          pos = args.index("--ignore")
          pos = pos + 1
          while pos < args.length and args[pos][0..1] != "--" and args[pos][0...1] != "-"
            @folders_to_ignore += [args[pos]]
            pos = pos + 1
          end
        end
      end
      
      def add_options_to_config(config_dict)
        if !config_dict.has_key?("folder_blacklist")
          config_dict["folder_blacklist"] = []
        end
        
        if not @folders_to_ignore.nil?
          config_dict["folder_blacklist"] = config_dict["folder_blacklist"] + @folders_to_ignore
        end
        
        return config_dict
      end
      
      def run_internal(command, args, config_dict)
        klass, method = parse(command)
        
        config_dict = add_options_to_config(config_dict)
        
        runner = klass.new(args, config_dict)
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

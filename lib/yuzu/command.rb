require 'yaml'

require 'commands/base'
require 'argparse'

require 'helpers/object'
require 'helpers/string'

# Load all the commands.
Dir["#{File.dirname(__FILE__)}/commands/*"].each { |c| require c }


CONFIG_NOT_FOUND_MESSAGE = \
%Q{Please run this from the root of your project, in the folder containing
yuzu.yml or config/yuzu.yml. Or use 'create' to make a new project.}


module Yuzu::Command

  def self.run(command_str, args)
    start = Time.now

    options = ArgParser.parse(args)

    if command_str.nil?
      exit
    end

    command_class, method = parse(command_str.downcase)
    execute(command_class, method, args[1, args.length] || [], options)

    stop = Time.now
    delta = stop - start
    if options.output == :verbose
      $stderr.puts "Yuzu completed in #{delta} seconds."
    else
      $stderr.puts
    end
  end

  def self.parse(command_str)
    command, method = command_str.split(':').collect {|part| part.strip}
    method = method.nil? ? :index : method.to_sym

    return Yuzu::Command.const_get(command.capitalize), method
  rescue
    raise InvalidCommand
  end

  def self.execute(command_class, method, args, parsed_options)
    if command_class.requires_config?
      config_hash = load_config

      config = \
      Yuzu::Core::Config.new(
        config_hash,
        command_class.service_override,
        parsed_options
      )

      command_instance = command_class.new(args, config)
      command_instance.send(method)

    else
      command_instance = command_class.new(args)
      command_instance.send(method)
    end
  rescue => e
    $stderr.puts e.message
    $stderr.puts e.backtrace
    raise CommandFailed
  end

  def self.load_config
    config_location = locate_config

    if config_location.nil?
      $stderr.puts CONFIG_NOT_FOUND_MESSAGE
      Process.exit!(false)
    end

    YAML.load_file(config_location)
  end

  def self.locate_config
    possible_config_locations.each do |path|
      if File.exists?(path)
        return path
      end
    end
    return nil
  end

  def self.possible_config_locations
    [
      File.join(Dir.pwd, "yuzu.yml"),
      File.join(Dir.pwd, "config", "yuzu.yml")
    ]
  end

  class InvalidCommand < RuntimeError; end
  class CommandFailed  < RuntimeError; end
end


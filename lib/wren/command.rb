
require 'yaml'
require 'commands/base'
require 'helpers/object'
require 'helpers/string'

# Load all the commands.
Dir["#{File.dirname(__FILE__)}/commands/*"].each { |c| require c }


CONFIG_NOT_FOUND_MESSAGE = "Please run this from the root of your project, with the config file at \
project/wren.yml or project/config/wren.yml, typically your root project folder. \
Or use 'create' to make a new project."


module Wren::Command

  def self.run(command_str, args)
    start = Time.now

    command_class, method = parse(command_str.downcase)
    execute(command_class, method, args)

    stop = Time.now
    delta = stop - start
    puts "Wren completed in #{delta} seconds."
  end

  def self.parse(command_str)
    command, method = command_str.split(':').collect {|part| part.strip}
    method = method.nil? ? :index : method.to_sym

    return Wren::Command.const_get(command.capitalize), method
  rescue
    raise InvalidCommand
  end

  def self.execute(command_class, method, args)
    if command_class.requires_config?
      config_dict = load_config
      config = Wren::Core::Config.new(config_dict, command_class.service_override)

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
      File.join(Dir.pwd, "wren.yml"),
      File.join(Dir.pwd, "config", "wren.yml")
    ]
  end

  class InvalidCommand < RuntimeError; end
  class CommandFailed  < RuntimeError; end
end


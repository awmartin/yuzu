require 'yaml'
require 'helpers/import'

import 'helpers/object'
import 'helpers/string'
import 'yuzu/argparse'

# Load all the commands.
import 'yuzu/commands/base'
Dir.glob(File.join(File.dirname(__FILE__), "commands", "*")).each do |file|
  require file if not file.include?('base.rb')
end

module Yuzu::Command

CONFIG_NOT_FOUND_MESSAGE = \
%Q{Please run this from the root of your project, in the folder containing
yuzu.yml or config/yuzu.yml. Or use 'create' to make a new project.}

  # Execute the current command typically specified by the user on the command line.
  #
  # @param [String] command_str The command entered on the command line, e.g. "preview:text"
  # @param [Array] args An array of strings representing all the other arguments entered after the
  #   command_str.
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

  # Takes the command string and returns the class and method corresponding to the specified
  # command.
  #
  # @param [String] command_str The command entered by the user, e.g. "preview:text"
  def self.parse(command_str)
    command, method = command_str.split(':').collect {|part| part.strip}
    method = method.nil? ? :index : method.to_sym

    return Yuzu::Command.const_get(command.capitalize), method
  rescue
    raise InvalidCommand
  end

  # Execute the specified command, given the class, method, command arguments, and command-line
  # flags entered after the command (e.g. --verbose).
  #
  # @param [Command] command_class The class of the requested command.
  # @param [Symbol] method The method to execute, e.g. :text or :all.
  # @param [Array] args An Array of Strings holding the non-flagged arguments after the command.
  # @param [Array] parsed_options An Array of Strings with the flagged arguments (e.g. --verbose)
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

  # Loads the configuration file yuzu.yml.
  #
  # @return [Hash] Containing the YAML structure of the yuzu.yml file.
  def self.load_config
    config_location = locate_config

    if config_location.nil?
      $stderr.puts CONFIG_NOT_FOUND_MESSAGE
      Process.exit!(false)
    end

    YAML.load_file(config_location)
  end

  # Returns the location of the configuration file when found.
  #
  # @return [String] A path relative to the active project folder.
  def self.locate_config
    possible_config_locations.each do |path|
      if File.exists?(path)
        return path
      end
    end
    return nil
  end

  # Returns the acceptable locations of the yuzu.yml file that Yuzu will search for on commands that
  # need a configuration.
  #
  # @return [Array] List of Strings of paths relative to the project folder.
  def self.possible_config_locations
    [
      File.join(Dir.pwd, "yuzu.yml"),
      File.join(Dir.pwd, "config", "yuzu.yml")
    ]
  end

  class InvalidCommand < RuntimeError; end
  class CommandFailed  < RuntimeError; end
end


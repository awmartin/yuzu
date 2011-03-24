module Wren::Command
	class Help < Base
	  def index
	    if @args.first.nil?
	      puts <<-eos
-------
Available Commands

help                              # Show this help page.
help [command]                    # Help about the particular command.

preview [filenames]               # Update the preview with the files listed.
preview:all                       # Update all the processable files in the preview.
preview:images                    # Copy all the images into the preview folder.
preview:resources
preview:assets

publish [filenames]
publish:all
publish:images
publish:resources
publish:assets

create                            # Creates a new wren project, sass and config file.

generate:config                   # Generates a blank configuration file in the current folder.

watch                             # Starts the auto-updater.

-------
Commands not implemeted yet.

generate:pdf [filename]           # Generates a pdf for the given file.

-------
External Commands

git commit

The third form, git commit, requires the file tree to be tracked by a git
repository. There is an included post-commit hook script that updates the
files changed in the last commit and all their dependants. Note: This git
repo should be set to ignore binary assets like images and pdfs.

      eos
      else
        klass, method = parse @args.first
        help_str = klass.help(method).to_s
        puts help_str
      end
    end
    
    def parse(command)
			parts = command.split(':')
			case parts.size
				when 1
					begin
						return eval("Wren::Command::#{command.capitalize}"), :default
					rescue NameError, NoMethodError
						return Wren::Command::App, command
					end
				when 2
					begin
					  # This isn't working...
						return eval("Wren::Command::#{parts[0].capitalize}"), parts[1].to_sym
					rescue NameError
						raise InvalidCommand
					end
				else
					raise InvalidCommand
			end
		end
  end
end
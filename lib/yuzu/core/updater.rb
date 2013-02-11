require 'core/visitor'
require 'helpers/path'
require 'core/siteroot'



module Yuzu::Core
  BOLD = "\033[1m"
  WHITE = "\033[37m"
  ENDC = "\033[0m"

  # Updater is the primary mechanism to update a website and filter for the files that need
  # updating.
  class Updater

    def initialize(uploader, config)
      @uploader = uploader
      @config = config

      @siteroot = SiteRoot.new(@config)

      $stderr.puts "Updater initialized..." if @config.verbose?
    end

    def update_all
      $stderr.puts "Updating all..." if @config.verbose?

      filter = proc {|c| (c.processable? or c.resource? or c.image? or c.asset?) and not c.hidden?}
      update_by_filter(filter)
    end

    def update_text
      $stderr.puts "Updating text files..." if @config.verbose?

      filter = proc {|c| c.processable? and not c.hidden?}
      update_by_filter(filter)
    end

    def upload_new_images(known_images=[])
      filter = proc {|c| c.image? and not c.hidden? and not known_images.include?(c)}
      update_by_filter(filter)
    end

    def upload_all_images
      filter = proc {|c| c.image? and not c.hidden?}
      update_by_filter(filter)
    end

    def upload_all_assets
      filter = proc {|c| c.asset? and not c.hidden?}
      update_by_filter(filter)
    end

    def upload_all_resources
      filter = proc {|c| c.resource? and not c.hidden?}
      update_by_filter(filter)
    end

    def upload_all_css
      filter = proc {|c| c.path.extension == ".css" and not c.hidden?}
      update_by_filter(filter)
    end

    def update_by_filter(proc_filter)
      updated = []
      visit = Visitor.new(proc_filter)

      visit.traverse(@siteroot) do |file|
        update_file(file)
        updated.push(file)
      end

      updated
    end

    # Update a single WebsiteFile. This effectively initiates the uploader to publish the file to
    # the destination specified by the currently selected service.
    def update_file(website_file)
      $stderr.puts "#{BOLD}#{WHITE}Updating #{website_file}#{ENDC}#{ENDC}" if @config.verbose?

      if website_file.processable?
        @uploader.upload(website_file.remote_path, website_file.html_contents)

      elsif website_file.resource? or website_file.image? or website_file.asset?
        f = File.open(website_file.path.absolute, "r")
        @uploader.upload(website_file.remote_path, f)
        f.close

      else
        $stderr.puts "Can't update #{website_file}." if @config.verbose?

      end
    end

    # Update a particular list of files. This is relatively expensive as it requires searching
    # through the file tree, but it should work well for a few files.
    #
    # @param [Array] files_to_update An Array of Strings holding absolute file paths or paths
    #   relative to the project folder.
    def update_these(files_to_update=[])
      $stderr.puts "Calling Updater#update_these..."

      files_to_update.each do |relative_path|
        p = Helpers::Path.new(relative_path)
        website_file = @siteroot.find_file_by_path(p)
        if not website_file.nil?
          update_file(website_file)
        else
          $stderr.puts "Couldn't find a WebsiteFile for #{p}"
        end
      end
    end  

    def done
      @uploader.close! unless @uploader.nil?
    end
  end
end

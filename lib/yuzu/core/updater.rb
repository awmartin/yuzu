require 'helpers/import'
import 'helpers/path'
import 'yuzu/core/visitor'
import 'yuzu/core/siteroot'


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

    # Updates the website files specified by the given filter. Optionally, you can specify a subtree
    # of the site to update by specifying "root".
    #
    # @param [Proc] proc_filter A proc that returns true/false when called.
    # @param [WebsiteFolder] root An optional WebsiteFolder object that specifies a subtree to
    #   update.
    # @return [Array] An array of the files updated.
    def update_by_filter(proc_filter, root=nil)
      updated = []
      visit = Visitor.new(proc_filter)
      update_root = root.nil? ? @siteroot : root

      visit.traverse(update_root) do |file|
        update_file(file)
        updated.push(file)
      end

      updated
    end

    # Update an explicit collection of WebsiteFiles. This effectively initiates the uploader to 
    # publish the files to the destination specified by the currently selected service.
    def update_file(website_file, force_paginated_siblings=false)
      $stderr.puts "#{BOLD}#{WHITE}Updating #{website_file}#{ENDC}#{ENDC}" if @config.verbose?

      if website_file.processable?
        @uploader.upload(website_file.remote_path, website_file.html_contents)

        if force_paginated_siblings and website_file.stash.has_key?(:paginated_siblings)
          paginated_siblings = website_file.stash[:paginated_siblings]
          paginated_siblings.each do |wf|
            @uploader.upload(wf.remote_path, wf.html_contents)
          end
        end

      elsif website_file.resource? or website_file.image? or website_file.asset?
        f = File.open(website_file.path.absolute, "r")
        @uploader.upload(website_file.remote_path, f)
        f.close

      elsif website_file.folder?
        filter_processable_files = proc {|c| c.processable? and not c.hidden?}
        update_by_filter(filter_processable_files, website_file)

      else
        $stderr.puts "Can't update #{website_file}." if @config.verbose?

      end
    end

    # Update a particular list of files. This is relatively expensive as it requires searching
    # through the file tree, but it should work well for a few files.
    #
    # @param [Array] files_to_update An Array of Strings holding absolute file paths or paths
    #   relative to the project folder.
    def update_these(files_to_update)
      if files_to_update.empty?
        update_all
        return
      end

      $stderr.puts "Updating files..." if @config.verbose?

      files_to_update.each do |relative_path|
        p = Helpers::Path.new(relative_path)
        website_file = @siteroot.find_file_by_path(p)

        if not website_file.nil?
          update_file(website_file, true)
        else
          $stderr.puts "Couldn't find a WebsiteFile for #{p}" if @config.verbose?
        end
      end
    end  

    def done
      @uploader.close! unless @uploader.nil?
    end
  end

end


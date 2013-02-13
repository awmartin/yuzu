require 'preprocessors/base'
require 'helpers/path'

module Yuzu::PreProcessors
  class InsertContentsPreProcessor < PreProcessor
    include Helpers

    def initialize
      @name = :insert_contents
      @directive = "INSERTCONTENTS"
    end

    def default(website_file=nil)
      nil
    end

    def value(website_file)
      match_path = match(website_file.raw_contents)
      raw_path = match_path.nil? ? default(website_file) : match_path
      Path.new(match_path)
    end

    def replacement(website_file, new_contents="")
      # Get the next match.
      match_path = match(new_contents)
      raw_path = match_path.nil? ? default(website_file) : match_path
      file_path = Path.new(raw_path)

      siteroot = website_file.root
      file_to_insert = siteroot.find_file_by_path(file_path)

      if not file_to_insert.nil?
        "\n" + file_to_insert.prefiltered_contents
      else
        insert_file(file_path)
      end
    end

    # A raw file insert. Load the file from disk and insert the contents directly.
    #
    # @param [Path] path refers to the file on disk.
    # @return [String] The contents of the file.
    def insert_file(path)
      if path.exists?
        f = File.open(path.absolute, "r")
        contents = f.read
        f.close
        contents
      else
        ""
      end
    end
  end

  PreProcessor.register(:insert_contents => InsertContentsPreProcessor)
end


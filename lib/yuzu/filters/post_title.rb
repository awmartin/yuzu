require 'helpers/import'

import 'yuzu/filters/base'

module Yuzu::Filters

  # This filter extracts a human-friendly title for the WebsiteFile being processed.
  class PostTitleFilter < Filter
    def initialize
      @directive = "TITLE"
      @name = :post_title
    end

    # Determines what the WebsiteFile's title is from a series of fallbacks:
    #
    # 1. TITLE(...) directive
    # 2. File-format specific, e.g. Markdown top-level header: # Title
    # 3. Filename
    #
    # @param [WebsiteFile] website_file The file whose title we're extracting.
    # @return [String] The title-case title of the post.
    def get_value(website_file)
      contents = website_file.raw_contents

      # Looks for the TITLE(...) directive first.
      title = match(contents)

      # Now for file-format specific titles from the content.
      title = title.nil? ? extract_title_from_contents(website_file) : title

      # The value() method incorporates the call to default() below.
      title
    end

    # Extracts the title of the WebsiteFile from its on-disk filename
    #
    # @param [WebsiteFile] website_file The file whose title we're extracting.
    # @return [String] The title of the file that comes from the filename.
    def default(website_file)
      extract_title_from_filename(website_file)
    end

    # Returns the title of the post as determined by the content Translators. Each has a method that
    # extracts the post title given the markup syntax of the content, for example:
    #
    #     # Markdown Title
    #     %h1 Textile Title
    #     <h1>HTML Title</h1>
    #
    # @param [WebsiteFile] website_file The WebsiteFile to extract the title from.
    # @return [String, NilClass] Either the title from the contents or nil.
    def extract_title_from_contents(website_file)
      website_file.class.translators.each_pair do |name, translator|
        if translator.translates?(website_file.path.extension)
          return translator.extract_title_from_contents(website_file.raw_contents)
        end
      end
      nil
    end

    # Derives the title from the file's filename, following the same conventions for extracting the
    # post's publication date from the filename. For example, all of these return the same post
    # title:
    #
    #     This Is The Post Title
    #
    #     this-is-the-post-title.md
    #     2013/01/this-is-the-post-title.md
    #     2013/01/01-this-is-the-post-title.md
    #     2013-01-01-this-is-the-post-title.md
    # 
    # @param [Path] path The path object represented by the current WebsiteFile.
    # @return [String] The title of the post.
    def extract_title_from_filename(website_file)
      name = website_file.path.basename
      raw_path = website_file.path.relative
      is_index = website_file.index?

      tr = nil
      tr = is_index ? name_for_index_files(website_file.parent)        : tr
      tr = tr.nil?  ? folder_date_with_day_in_filename(raw_path, name) : tr
      tr = tr.nil?  ? folder_date(raw_path, name)                      : tr
      tr = tr.nil?  ? date_in_filename(name)                           : tr

      tr.titlecase
    end

    # Return the proper name for files that render "index.html" files.
    #
    # @param [WebsiteFolder] parent The parent of the index file that needs a title.
    # @return [String] The title as a String.
    def name_for_index_files(parent)
      parent.root? ? "Home" : parent.path.rootname.titlecase
    end

    # Look for the YYYY/MM/DD-title-here.md pattern.
    def folder_date_with_day_in_filename(raw_path, basename)
      m = raw_path.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}\-/)
      m.nil? ? nil : basename[3..-1]
    end

    # Look for the YYYY/MM/title-here.md pattern.
    def folder_date(raw_path, basename)
      m = raw_path.match(/[0-9]{4}\/[0-9]{2}\//)
      m.nil? ? nil : basename
    end

    # Remove the YYYY-MM-DD- date prefix if present.
    def date_in_filename(basename)
      date_prefix = /[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/
      basename.sub(date_prefix, "")
    end

  end
  Filter.register(:post_title => PostTitleFilter)
end


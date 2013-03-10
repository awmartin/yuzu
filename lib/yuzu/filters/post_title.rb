require 'helpers/import'

import 'yuzu/filters/base'

module Yuzu::Filters
  class PostTitleFilter < Filter
    def initialize
      @directive = "TITLE"
      @name = :post_title
    end

    def default(website_file)
      extract_title_from_filename(website_file.path)
    end

    def get_value(website_file)
      contents = website_file.raw_contents

      title = match(contents)

      if title.nil? and website_file.markdown?
        m = contents.match(/^#\s+.*?\n/)
        title = m.nil? ? nil : m[0].sub("#", "").strip
      end
      return title
    end

    def extract_title_from_filename(path)
      post_filename = nil
      name = path.rootname
      raw_path = path.relative

      if name.include?("index")
        # If we're looking at an index, grab the folder name instead.
        post_filename = path.parent.rootname
        return post_filename.blank? ? "Home" : post_filename.titlecase
      end

      if post_filename.nil?
        # Look for the YYYY/MM/DD-title-here.md pattern.
        m = raw_path.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}\-/)
        if not m.nil?
          post_filename = name[3..-1]
        end
      end

      if post_filename.nil?
        # Look for the YYYY/MM/title-here.md pattern.
        m = raw_path.match(/[0-9]{4}\/[0-9]{2}\//)
        if not m.nil?
          post_filename = name
        end
      end
    
      if post_filename.nil?
        post_filename = name
      end

      # Remove the YYYY-MM-DD- date prefix if present.
      post_filename = post_filename.sub(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/, "")
    
      return post_filename.titlecase
    end

  end
  Filter.register(:post_title => PostTitleFilter)
end


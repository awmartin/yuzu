module Wren::Filters
  class PostTitleFilter < Base
    def init
    end

    def directive
      "TITLE"
    end

    def name
      :post_title
    end

    def value(match)
      titleize(match.to_s)
    end

    def alternative_value(file_cache)
      extract_title_from_filename(file_cache.raw_path)
    end

    def extract_title_from_filename(raw_path)
      post_filename = File.basename(raw_path)
    
      if post_filename.include?("index")
        # If we're looking at an index, grab the folder name instead.
        post_filename = raw_path.split("/")[-2]
        if post_filename.blank?
          post_filename = "Home"
        end
      end
    
      # Look for the YYYY/MM/DD-title-here.md pattern.
      m = raw_path.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}\-/)
      if not m.nil?
        # For now, just remove the first 3 characters.
        post_filename = post_filename[3..-1]
      end
    
      # Remove the YYYY-MM-DD- date prefix if present.
      post_filename = post_filename.sub(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/, "")
    
      return titleize(post_filename)
    end

  end
end


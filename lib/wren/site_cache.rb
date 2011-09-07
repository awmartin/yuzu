require 'file_cache'

class SiteCache

  def initialize config
    @config = config

    @cache = {}
    Dir["**/*"].each do |path|
      if not path.includes_one_of? @config.folder_blacklist
        @cache[path] = FileCache.new path, config
      end
    end

    @cache.each_pair do |path, file_cache|
      file_cache.site_cache = self
    end
    
    new_pages = {}
    # Run the pagination pass.
    @cache.each_pair do |path, file_cache|
      if file_cache.paginate?
        # Calculate the number of pages.
        # Create new file caches for each page.
        num_pages = file_cache.num_pages
        
        num_pages.times do |i|
          if i > 0
            new_fc = FileCache.new(path, config, i + 1)
            new_fc.site_cache = self # This is ok since nothing depends on the new page
            
            new_pages[new_fc.paginated_path] = new_fc
          end
        end
      end # end paginate test
    end # end cache loop

    # Add the new pages to the cache, so they are updated as well.
    @cache.update(new_pages)
  end
  
  def cache
    @cache
  end

end

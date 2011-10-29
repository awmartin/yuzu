require 'file_cache'

class SiteCache

  def initialize config
    @config = config

    # The actual cache is a Hashmap of path -> FileCache object.
    @cache = {}
    Dir["**/*"].each do |path|
      if not path.includes_one_of? @config.folder_blacklist
        @cache[path] = FileCache.new(path, config)
      end
    end

    # Hand a reference to the entire SiteCache to every FileCache
    @cache.each_pair do |path, file_cache|
      file_cache.site_cache = self
    end
    
    new_pages = {}
    # Run the pagination pass.
    @cache.each_pair do |path, file_cache|
      if file_cache.paginate?
        # Calculate the number of pages.
        # Create new file caches for each new page.
        num_pages = file_cache.num_pages
        
        num_pages.times do |i|
          if i > 0
            page_num = i + 1
            new_fc = FileCache.new(path, config, page_num)
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

require 'file_cache'

class SiteCache

  def initialize config
    @config = config

    # The actual cache is a Hashmap of path -> FileCache object.
    @cache = {}
    Dir["**/*"].each do |path|
      if not @config.is_blacklisted?(path) and not @config.is_hidden?(path)
        @cache[path] = FileCache.new(path, config)
      end
    end

    # Hand a reference to the entire SiteCache to every FileCache
    @cache.each_pair do |path, file_cache|
      file_cache.site_cache = self
    end
    
    create_category_folders
    
    # Do this last...
    create_paginated_pages
  end
  
  def create_paginated_pages
    # Run the pagination pass.
    new_pages = {}
    
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
  
  # Collect the current categories from the files...
  def categories
    tr = []
    @cache.each_pair do |path, file_cache|
      if file_cache.processable?
        if not file_cache.categories.nil?
          tr += file_cache.categories.collect {|cat| cat.to_s.downcase}
        end
      end
    end
    return tr.uniq
  end
  
  def create_category_folders
    uncat_dir = File.join(@config.blog_dir, "uncategorized/index.md")
    uncat_file_cache = FileCache.new(uncat_dir, @config)
    uncat_file_cache.raw_contents = category_page_contents("uncategorized")
    
    tr = {uncat_dir => uncat_file_cache}
    categories.each do |category|
      path = File.join(@config.blog_dir, category.to_s.dasherize, "index.md")
      new_fc = FileCache.new(path, @config)
      new_fc.site_cache = self
      new_fc.raw_contents = category_page_contents(category)
      tr[path] = new_fc
    end
    @cache.update(tr)
  end
  
  def category_page_contents category="uncategorized"
    category_template_path = File.join(@config.template_dir, "category.txt")
    f = File.open(category_template_path, "r")
    tr = f.readlines.join
    f.close
    
    return tr.gsub("CATEGORY", category)
  end
end

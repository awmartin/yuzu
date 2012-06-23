

# @param contents String - Single string containing the contents of the file to search through.
# @returns folder path(String), start position(integer), count of files(integer), 
#   blocks per row(integer), block template(String)
def extract_first_catalog contents
  matches = contents.match(/INSERTCATALOG\(([\w\s\,\.\-\/_]*)\)/)
  
  if not matches.nil?
    arg_str = matches[0].to_s.gsub("INSERTCATALOG(","").gsub(")","")
    args = arg_str.split(",").collect {|a| a.strip}
    
    path_of_folder_to_insert = remove_leading_slash(args[0].to_s)
    
    if args.length > 1
      if args[1] == "PAGINATE"
        start = -1 # TODO: Magic number!
      else
        start = 0
      end
    else
      start = 0
    end
    
    count = args.length > 2 ? args[2].to_i : 10
    blocks_per_row = args.length > 3 ? args[3].to_i : 1
    block_template = args.length > 4 ? args[4].to_s : "_block.haml"
    category = args.length > 5 ? args[5].to_s : nil
    sort_by = args.length > 6 ? args[6].to_s : :date_reversed
    deep = args.length > 7 ? (args[7] == "DEEP" ? true : false) : true
    
    return path_of_folder_to_insert, start, count, blocks_per_row, block_template, category, sort_by, deep
  else
    return nil, nil, nil, nil, nil, nil
  end
end


def insert_catalogs site_cache, process_contents, page=1
  tr = process_contents.gsub(/INSERTCATALOG\(([\w\s\,\.\-\/_]*)\)/) do |s|
    arg_str = s.gsub("INSERTCATALOG(","").gsub(")","")
    Catalog.new(site_cache, arg_str, page).html_contents
  end
  return tr
end

# TODO: Support pagination?
class Catalog
  def initialize site_cache, str, page=1
    @site_cache = site_cache.cache
    
    args = str.split(",").collect {|a| a.strip}
    
    # Extract the arguments.
    @folder_to_insert = args[0].to_s
    
    if args.length > 1
      if args[1] == "PAGINATE"
        @start = 0 #-1 # TODO: Magic number!
      else
        @start = args[1].to_i
      end
    else
      @start = 0
    end
    
    @count = args.length > 2 ? args[2].to_i : 10
    @blocks_per_row = args.length > 3 ? args[3].to_i : 1
    @block_template = args.length > 4 ? args[4].to_s : "_block.haml"
    @category = args.length > 5 ? args[5].to_s : nil
    if not @category.nil? 
      if @category.strip.blank?
        @category = nil
      end
    end
    @sort_by = args.length > 6 ? args[6].to_s.to_sym : :date_reversed
    # DEEP or FLAT
    @deep = args.length > 7 ? (args[7] == "DEEP" ? true : false) : true
    
    @file_cache = @site_cache[@folder_to_insert]
  end

  def list_of_files
    
    if @list_of_files.nil?
      if @file_cache.nil?
        return []
      end
      
      if @category.nil?
        files = @file_cache.catalog_children(nil, @sort_by, @deep)
      else
        files = @file_cache.catalog_children(nil, @sort_by, @deep).select { |f| 
                    f.categories.include?(@category)}
      end

      if files.length == 0
        @list_of_files = []
      else
        if @count > 0
          @list_of_files = files[@start...(@count + @start)]
        else
          @list_of_files = files
        end
      end

    end
    @list_of_files
  end

  def html_contents
    make_rows = (@blocks_per_row.to_i > 0)
    
    start_row = "\n\n<div class='row'>\n\n"
    end_row = "\n\n</div>\n\n"
    
    result = ""
    if list_of_files.blank?
      puts "WARNING: No posts found for catalog: #{@folder_to_insert}"
      return result
    end
    
    result += start_row
    
    list_of_files.each_index do |i|
      file_cache = list_of_files[i]
      actual_index = i + @start
      
      if actual_index >= @start
        # Need j for start values that are not multiples of blocks_per_row
        # For example, offsets of 1 will have the "last" css class and <hr> element inserted properly.
        j = actual_index - @start 
        
        if make_rows
          if j % @blocks_per_row == 0 and i != 0
            result += end_row
            result += "\n\n<hr>\n\n"
            result += start_row
          end
        end
        
        css_class = ""
        if make_rows
          # In a 12-column grid. TODO: make this configurable.
          num_columns_12 = 12 / @blocks_per_row
          css_class = "span#{num_columns_12}"
          
          if ((j % @blocks_per_row) == (@blocks_per_row - 1))
            css_class += " last"
          end
        end
        
        lyt = LayoutHandler.new(file_cache)
        opts = {
          :klass => css_class
        }.update(file_cache.attributes)
        
        str = lyt.load_template(@block_template, opts)
        
        # Attempt to remove space-indentations. This was a dumb attempt to fix the stupid HAML
        # indentation which fucks up <pre> tags.
        str = str.gsub(/\n\s*/,"")
        
        result += str + "\n"
      end
    end
    
    result += end_row
    result += "\n\n<hr>\n\n"
    
    result
  end
end

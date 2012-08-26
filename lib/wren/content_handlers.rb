require 'pathname'
require 'stringio'


def get_file_type extension, config
  
  if extension.include? 'text'
    return :textile
  elsif extension.include? 'html'
    return :html
  elsif extension.include? 'haml'
    return :haml
  elsif extension.includes_one_of? ["markdown", "md", "mdown"]
    return :markdown
  elsif extension.includes_one_of? config.image_extensions
    return :image
  elsif extension.includes_one_of? config.asset_extensions
    return :asset
  elsif extension.includes_one_of? config.resource_extensions
    return :resource
  elsif extension.includes_one_of? ["txt", "pde", "rb"]
    return :plaintext
  else
    return :unknown
  end

end


def get_first_html_paragraph contents
  html_pattern = /<p\b[^>]*>((.|\n)*?)<\/p>/
  lines = contents.split("\n")
  lines.each do |line|
    m = line.match(html_pattern)
    if not m.nil?
      return m[0], m[1]
    end
  end
  return nil
end

def strip_paragraph_style paragraph, file_type
  tr = ""
  if file_type == :textile
    tr = paragraph.gsub(/p\([A-Za-z0-9\.\-\_]*\)\.\s/,"")
  elsif file_type == :haml
    tr = paragraph.gsub(/(\%p)(\.[A-Za-z0-9\.\-\_]*)?\s/,"")
  end
  return tr.strip
end

def extract_first_image file
  file.rewind
  
  # Sometimes, the files have INSERTCONTENTS for their primary contents.
  str = file.readlines.join("\n")
  contents = insert_contents str
  lines = contents.split("\n")
  
  lines.each do |line|
    matches = line.match(/IMAGES\(([\w\:\,\.\-\/_]*)\)/)
    if not matches.nil?
      m = matches[0].gsub("IMAGES(","").gsub(")","")
      image = m.split(",")[0]
      return image
    end
  end
  return ""
end

def extract_title_from_filename raw_path
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
  
  # Regex removes the leading date for posts, e.g. 2011-05-28-
  return titleize(post_filename)
end

def extract_date_from_filename filename
  post_filename = filename.split("/").last
  m = post_filename.match(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/)
  if not m.nil?
    date_parts = post_filename.split("-")[0..2]
    return date_parts.join("-")
  else
    return nil
  end
end

def extract_date_from_folder_structure raw_path
  m = raw_path.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}\//)
  if not m.nil?
    date_parts = m.to_s.split("/")[0..2]
    return date_parts.join("-")
  else
    # Look for "2011/10/19-title-here.md"
    m = raw_path.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}\-/)
    if not m.nil?
      year = m.to_s.split("/")[0]
      month = m.to_s.split("/")[1]
      day = m.to_s.split("/")[2].sub("-", "")
      return [year, month, day].join("-")
    else
      return nil
    end
  end
end

def format_date date
  return "" if date.blank?
  months = {"01" => "January","02" => "February", "03" => "March", "04" => "April", 
    "05" => "May", "06" => "June", "07" => "July", "08" => "August", 
    "09" => "September", "10" => "October", "11" => "November", "12" => "December"}
  date_parts = date.split("-")[0..2]
  post_date = "#{date_parts[0]} #{months[date_parts[1]]} #{date_parts[2]}"
  return post_date
end

def remove_date_from_filename filename
  post_filename = File.basename(filename)
  return post_filename.sub(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/, "")
end


def build_title path, site_name, extracted_page_title=""
  
  if extracted_page_title.strip.blank?
    if File.directory? path
      page_title = titleize(remove_date_from_filename(File.basename(path)))
      html_title = "#{page_title} | #{site_name}"
      
    else
      if path.include?("index.")
        filename = File.basename(path).to_s
        tmp_path = path.gsub(filename, "").to_s.strip
        
        if tmp_path.blank?
          html_title = site_name
        else
          page_title = titleize(remove_date_from_filename(tmp_path))
          html_title = "#{page_title} | #{site_name}"
        end
      else
        page_title = titleize(remove_date_from_filename(File.basename(path)))
        html_title = "#{page_title} | #{site_name}"
      
      end
    end

  elsif path.blank? or is_root?(path)
    html_title = site_name

  else
    html_title = "#{extracted_page_title} | #{site_name}"
  
  end
  
  return html_title
end


def is_root? path
  if not File.directory?(path)
    extension = File.extname(path)
    path_without_filename = path.gsub(extension, "")
    if path_without_filename == "index"
      return true
    end
  else
    return false
  end
end

# Like File.join, but cleans up the leading ./ in paths like
# ./modules/index.text
def concat_path prepath="", postpath=""
  Pathname.new( File.join( prepath, postpath ) ).cleanpath.to_s
end

def replace_image_urls content, url
  return str.gsub(/((!+)((\(+)([\w\-_]*)(\)+))([\w.\/\-_%]*)(!+))|((!+)([\w.\/\-_%]*)(!+))/) do |s| 
    if s.include?('http://')
      # External image. Just return the match.
      s
    elsif s.include?(')')
      # Image has a class declared.
      s.gsub!(')',')' + url)
    else
      s.sub!('!','!' + url)
    end
  end
end

# Path helpers.........................................................

def filter_path path
  if path.include?("index")
    # Remove the index.
    index_file = File.basename(path)
    return path.sub(index_file, "")
  elsif not File.directory?(path)
    # Remove the file extension.
    ext = File.extname(path)
    return path.sub(ext,"")
  end
  return path
end

def html_path path=""
  ext = File.extname(path)
  return path.sub(ext, ".html")
end

def linked_path pageinfo, path=""
  return Pathname.new( File.join( @pageinfo.link_root.to_s, path.to_s ).to_s ).cleanpath.to_s
end

def path_to file
  if file.is_a?(String)
    if File.directory?(file)
      return file
    else
      return file.to_s.gsub(File.basename(file),"")
    end
  elsif file.is_a?(File)
    if File.directory?(file.path)
      return file.path
    else
      return file.path.gsub(File.basename(file.path),"")
    end
  end
end

def remove_trailing_slash path=""
  return "" if path.blank?
  
  if path[-1].chr == "/"
    return path.reverse.sub("/","").reverse
  end
  
  return path
end

def remove_leading_slash path=""
  return "" if path.blank?
  
  if path[0].chr == "/"
    return path.sub("/","")
  end
  
  return path
end

def add_leading_slash path=""
  return "" if path.blank?
  
  if path[0].chr != "/"
    return "/" + path
  end
  
  return path
end

def titleize str=""
  str.to_s.gsub( File.extname(str.to_s), "" ).gsub("-"," ").gsub("_"," ").gsub("/","").titlecase
end

def link_to text, url
  "<a href=\"#{url}\">#{text}</a>"
end

def demote_headers contents, file_type
  headers = []
  if file_type == :textile
    headers = ["h1.", "h2.", "h3.", "h4.", "h5.", "h6."]
  elsif file_type == :markdown
    headers = ["\n# ", "\n## ", "\n### ", "\n#### ", "\n##### ", "\n###### "]
  elsif file_type == :haml
    headers = ["%h1", "%h2", "%h3", "%h4", "%h5", "%h6"]
  end
  
  if headers.blank?
    return contents
  else
    i = 4
    5.times do
      contents.gsub!(headers[i], headers[i + 1])
      i -= 1
    end
  end
  return contents
end

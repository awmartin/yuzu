require 'pathname'

def extract_first_paragraph file, file_type
  file.rewind
  
  paragraph = ""
  if file_type == :textile
    headers = /h1\.\s|h2\.\s|h3\.\s|h4\.\s/
  elsif file_type == :haml
    headers = /\%h1\s|\%h2\s|\%h3\s|\%h4\s/
  end
  past_first_header = false
  
  # Sometimes, the files have INSERTCONTENTS for their primary contents.
  str = file.readlines.join("\n")
  contents = insert_contents str
  lines = contents.split("\n")
  
  lines.each do |line|
    if line.include?("p(intro). ")
      return line.gsub("p(intro). ","")
    elsif line.include?("%p.intro ")
      return line.gsub("%p.intro ","")
    end
  end
  
  # Check to see if there is a header at all...
  # TODO: Really should check to see if a paragraph shows up before a header.
  if contents.match(headers).nil?
    past_first_header = true
  end
  
  lines.each do |line|
    if past_first_header and not line.strip.blank? and line.strip[0].chr != "!" and line.match(headers).blank?
      paragraph = line.to_s.gsub("\n","").strip
      break
    end
    
    if not line.match(headers).blank? and not past_first_header
      past_first_header = true
    end
  end
  
  # Remove %p.class from the found paragraph.
  if file_type == :textile
    paragraph.gsub!(/p\([A-Za-z0-9\.\-\_]*\)\.\s/,"")
  elsif file_type == :haml
    paragraph.gsub!(/(\%p)(\.[A-Za-z0-9\.\-\_]*)?\s/,"")
  end
  
  return paragraph
end

def extract_first_image file
  file.rewind
  
  # Sometimes, the files have INSERTCONTENTS for their primary contents.
  str = file.readlines.join("\n")
  contents = insert_contents str
  lines = contents.split("\n")
  
  lines.each do |line|
    matches = line.match(/IMAGES\(([A-Za-z0-9\,\.\-\/_]*)\)/)
    if not matches.nil?
      m = matches[0].gsub("IMAGES(","").gsub(")","")
      image = m.split(",")[0]
      return image
    end
  end
  return ""
end

def extract_title_from_filename filename
  post_filename = File.basename(filename)
  
  if post_filename.include?("index")
    # If we're looking at an index, grab the folder name instead.
    post_filename = filename.split("/")[-2]
    if post_filename.blank?
      post_filename = "Home"
    end
  end
  
  # Regex removes the leading date for posts, e.g. 2011-05-28-
  return titleize( post_filename.sub(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/,"") )
end

def extract_date_from_filename filename
  post_filename = filename.split("/").last
  if not post_filename.match(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/).nil?
    months = {"01" => "January","02" => "February", "03" => "March", "04" => "April", "05" => "May", "06" => "June",
              "07" => "July", "08" => "August", "09" => "September", "10" => "October", "11" => "November", "12" => "December"}
    date_parts = post_filename.split("-")[0..2]
    post_date = date_parts[0].to_s + " " + months[date_parts[1]] + " " + date_parts[2].to_s
    return post_date
  else
    return ""
  end
end

def remove_date_from_filename filename
  post_filename = File.basename(filename)
  return post_filename.sub(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}\-/, "")
end

def build_title path, pageinfo
  path = filter_path(path)
  clean = Pathname.new(path).cleanpath.to_s
  last = clean.to_s.split('/').last
  
  if last.blank? or last == "."
    html_title = pageinfo.site_name
    title = pageinfo.site_name
  else
    html_title = titleize(remove_date_from_filename last).to_s
    title = html_title.to_s + " | " + pageinfo.site_name.to_s
  end
  
  return title.to_s
end


# Like File.join, but cleans up the leading ./ in paths like
# ./modules/index.text
def concat_path prepath="", postpath=""
  Pathname.new( File.join( prepath, postpath ) ).cleanpath.to_s
end

def replace_image_urls content, url
  return str.gsub(/((!+)((\(+)([A-Za-z0-9\-_]*)(\)+))([A-Za-z0-9.\/\-_%]*)(!+))|((!+)([A-Za-z0-9.\/\-_%]*)(!+))/) do |s| 
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
  if path.include?("index.")
    # Remove the index.
    index_file = File.basename(path)
    path.sub!(index_file, "")
  elsif not File.directory?(path)
    # Remove the file extension.
    ext = File.extname(path)
    path.sub!(ext,"")
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

def get_file_type config, file
  if file.is_a?(String)
    file_ext = file.split(".").last.to_s
    return :unknown if file_ext.blank?
  elsif file.is_a?(File)
    file_ext = File.extname(file.path)
  else
    return :unknown
  end
  
  if file_ext.includes_one_of? config.image_extensions
    return :image
  elsif file_ext.includes_one_of? config.asset_extensions
    return :asset
  elsif file_ext.includes_one_of? ["txt","pde","rb"]
    return :plaintext
  elsif file_ext.include? 'text'
    return :textile
  elsif file_ext.include? 'html'
    return :html
  elsif file_ext.include? 'haml'
    return :haml
  else
    return :unknown
  end
end


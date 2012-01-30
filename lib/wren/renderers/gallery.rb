require 'haml'

def render_gallery images, config
  gallery_path = File.join(config.template_dir, "_gallery.haml")
  
  if File.exists?(gallery_path)
    f = File.open(gallery_path, "r")
    contents = f.readlines.join
    f.close
    return Haml::Engine.new(contents, {:format => :html5}).render(Object.new, {:images => images})
  else
    return render_gallery_fallback(images)
  end
end

# Fallback in case the _gallery.haml file is no where to be found.
def render_gallery_fallback images
  if images.length == 0
    return ""
  end
  
  gallery = "\n\n<div class='slideshow'>\n"
  images.each_index do |i|
    big_image = images[i].gsub(".", "-large.")

    visibility = i == 0 ? "display:block;z-index:2;" : "display:none;z-index:1;"

    gallery += "
<div class='slide' id='slide-#{i}' style='#{visibility}'>
<img src='#{big_image}'>
</div>
"
  end
  
  gallery += "</div>\n"
  gallery += "
<script type='text/javascript' charset='utf-8'>
var count = #{images.length};
</script>
"
  gallery += "<div class='gallery-thumbnails'>"
  
  images.each_index do |i|
    image = images[i]
    thumb_url = image.gsub(".", "-small.")
    
    klass = i % 6 == 5 ? "gallery-thumb last" : "gallery-thumb"
    gallery += "
<div class='#{klass}'>
<a href='#' onclick='slide(#{i});return false;'>
<img src='#{thumb_url}'>
</a>
</div>"
  end
  
  # Fill in the rest of the row with blank thumbnails.
  # The second "% 6" ensures there isn't an extra blank row added
  # when there are exactly 6 images.
  num_blanks = (6 - images.length % 6) % 6
  num_blanks.times do |i|
    klass = (images.length+i) % 6 == 5 ? 'gallery-thumb last' : "gallery-thumb"
    gallery += "<div class='#{klass}'>&nbsp;</div>"
  end
  
  gallery += "</div>\n\n"
  gallery += "<hr>"
  gallery
end

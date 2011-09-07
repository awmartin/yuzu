# TODO: Make this a partial, e.g. _gallery.haml
def render_gallery images, file_type, link_root
  if images.length == 0
    return ""
  end
  gallery = ""

  if file_type == :hamlblah
    gallery += "\n.slideshow\n"
    images.each_index do |i|
      big_image = images[i].gsub(".", "-large.")
      if i == 0
        visibility = "display:block;z-index:2;"
      else
        visibility = "display:none;z-index:1;"
      end
      gallery += "
.slide#slide-#{i}(style='#{visibility}')
%img{:src=>'#{big_image}'}
"
    end
    gallery += "
:javascript
var count = #{images.length};
"
    gallery += ".gallery-thumbnails\n"
  else
    gallery = "\n\n<div class='slideshow'>\n"
    images.each_index do |i|
      big_image = images[i].gsub(".", "-large.")
      if i == 0
        visibility = "display:block;z-index:2;"
      else
        visibility = "display:none;z-index:1;"
      end
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
  end
  
  images.each_index do |i|
    image = images[i]
    thumb_url = image.gsub(".", "-small.")
    if file_type == :hamlblah
      if (images.length+i) % 6 == 5
        gallery += "
.gallery-thumb.last
%a{:href => '#', :onclick => 'slide(#{i});return false;'}
  %img{:src => '#{thumb_url}'}
"
      else
        gallery += "
.gallery-thumb
%a{:href => '#', :onclick => 'slide(#{i});return false;'}
  %img{:src => '#{thumb_url}'}
"
      end
    else
      if i % 6 == 5
        gallery += "
<div class='gallery-thumb last'>
<a href='#' onclick='slide(#{i});return false;'>
<img src='#{thumb_url}'>
</a>
</div>"
      else
        gallery += "
<div class='gallery-thumb'>
<a href='#' onclick='slide(#{i});return false;'>
<img src='#{thumb_url}'>
</a>
</div>"
      end
    end
  end
  
  num_blanks = 6 - images.length%6
  num_blanks.times do |i|
    if file_type == :hamlblah
      if (images.length+i) % 6 == 5
        gallery += "  .gallery-thumb.last &nbsp;\n"
      else
        gallery += "  .gallery-thumb &nbsp;\n"
      end
    else
      if (images.length+i) % 6 == 5
        gallery += "<div class='gallery-thumb last'>&nbsp;</div>"
      else
        gallery += "<div class='gallery-thumb'>&nbsp;</div>"
      end
    end
  end
  
  if file_type == :hamlblah
    gallery += "%hr\n"
  else
    gallery += "</div>\n\n"
    gallery += "<hr>"
  end

  gallery.gsub("LINKROOT", link_root)
end

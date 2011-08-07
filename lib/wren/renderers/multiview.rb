
class MultiviewRenderer
  def initialize config, pageinfo
    @config = config
    @pageinfo = pageinfo
  end

  def make_slideshow original_contents, local_path
    puts "--"
    puts "Generating the slideshow."
  
    # Render the slideshow view as well.
    slideshow = wrap_slides original_contents
    slideshow_contents = RedCloth.new(slideshow).to_html
  
    js = insert_javascript "slideshow.js"
    wrapped_contents = wrap_with_layout(slideshow_contents, js)
    wrapped_contents.gsub!("class='content'", "class='content slideshow'")
  
    post_process slideshow_path( local_path ), wrapped_contents
  
    puts "Done with slideshow."
    puts "--"
  end

  def make_accordion original_contents, local_path
    puts "--"
    puts "Generating the accordion."
  
    accordion = wrap_accordion original_contents
    accordion_contents = RedCloth.new(accordion).to_html
  
    js = insert_javascript "accordion.js"
    wrapped_contents = wrap_with_layout(accordion_contents, js)
    wrapped_contents.gsub!("class='content'", "class='content accordion'")
  
    post_process accordion_path( local_path ), wrapped_contents
  
    puts "Done with accordion."
    puts "--"
  end

  def multiview where=""
    "<div class=\"multiview\">Render as " +
    [
      #"<a href=\"#{where}\">Lecture Notes</a>",
      #"<a href=\"#{where}?as=outline\">Outline</a>",
      "<a href=\"#{linked_path(@pageinfo, html_path(slideshow_path(where)))}\">Slideshow</a>",
      "<a href=\"#{linked_path(@pageinfo, html_path(accordion_path(where)))}\">Accordion</a>"
    ].join(" | ") + 
    "</div>"
  end

  def insert_multiview str, local_path
    puts "Replacing MULTIVIEW."
    if str.include?("MULTIVIEW")
      make_slideshow str.gsub("MULTIVIEW",""), local_path
      make_accordion str.gsub("MULTIVIEW",""), local_path
      tr = str.gsub( "MULTIVIEW", multiview(local_path) )
    end
    return tr
  end
end
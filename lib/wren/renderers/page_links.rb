require 'content_handlers'

def render_page_links num_pages=1, root_path="", current_page=0
  # Ensure root_path is a folder
  root_folder = path_to(root_path)
  links = []
  num_pages.times do |page_number|
    label = (page_number + 1).to_s
    if page_number+1 == current_page
      links += ["<span>#{label}</span>"]
    else
      if page_number+1 == 1
        links += [link_to(label, concat_path(root_folder, "index.html"))]
      else
        links += [link_to(label, concat_path(root_folder, "index_#{page_number + 1}.html"))]
      end
    end
  end
  return "<div class='page_links'>" + links.join(" ") + "</div>"
end

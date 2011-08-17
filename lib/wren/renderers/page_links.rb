require 'content_handlers'

def render_page_links num_pages=1, root_path=""
  # Ensure root_path is a folder
  root_folder = path_to(root_path)
  links = []
  num_pages.times do |page_number|
    label = (page_number + 1).to_s
    if page_number == 0
      links += [link_to(label, concat_path(root_folder, "index.html"))]
    else
      links += [link_to(label, concat_path(root_folder, "index_#{page_number + 1}.html"))]
    end
  end
  return links.join(" | ")
end

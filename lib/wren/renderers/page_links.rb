

def render_page_links num_pages=1, root_path="", current_page=0
  # Ensure root_path is a folder
  if not File.directory? root_path
    root_folder = root_path.gsub(File.basename(root_path), "")
  else
    root_folder = root_path
  end

  links = []

  num_pages.times do |page_number|
    label = (page_number + 1).to_s

    if page_number+1 == current_page
      links += ["<span>#{label}</span>"]
    else
      if page_number+1 == 1
        links += [link_to(label, File.join(root_folder, "index.html"))]
      else
        links += [link_to(label, File.join(root_folder, "index_#{page_number + 1}.html"))]
      end
    end
  end

  return "<div class='page_links'>" + links.join(" ") + "</div>"
end

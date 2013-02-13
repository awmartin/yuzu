require 'content/sample_project'

module Yuzu::Command

  # Create produces a new content such as a new yuzu website project or new blog post.
  class Create < ConfiglessCommand
    include Yuzu::Content

    def initialize(args)
      @args = args
    end

    def index

      sample_project = nil
      sample_project_name = @args.length > 0 ? @args[0] : "default"

      $stderr.puts "Creating a new Yuzu '#{sample_project_name}' project in this directory..."

      if SampleProject.exists?(sample_project_name)
        sample_project = SampleProject.new(sample_project_name)
        sample_project.deliver!
      else
        raise RuntimeError, "Sample project called #{sample_project_name} was not found."
      end

      $stderr.puts "Done!"
      $stderr.puts
      $stderr.puts "Now try:"
      $stderr.puts
      $stderr.puts "   yuzu preview"
      $stderr.puts

      preview_url = sample_project.new_config['services']['preview']['link_root'] + '/index.html'
      $stderr.puts "And point your web browser to #{preview_url}"

      $stderr.puts "to see your new Yuzu site."
      $stderr.puts
      $stderr.puts "Remember to edit yuzu.yml to set your site settings, preview path, and remote host."
    end

    # args[1] is a string that contains the blog title
    # Creates a new post with the lower-case title, TITLE() directive, and prefix publication date.
    def post
      t = Time.now
      day_str = sprintf "%02d", t.day
      mon_str = sprintf "%02d", t.month
      year_str = sprintf "%04d", t.year
      base_filename = @args.first.gsub(" ", "-").downcase

      full_filename = "#{year_str}-#{mon_str}-#{day_str}-#{base_filename}.md"
      file_path = File.join(@config.blog_dir, full_filename)

      post_title = @args.first
      first_sentence = "The title of this post is #{post_title}."
      filler_sentence = %Q(
Lorem ipsum dolor sit amet, consectetur adipisicing elit, 
sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim 
ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip 
ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate 
velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat 
cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id 
est laborum.).gsub("\n", "")
      contents = ["TITLE(#{post_title})", 
                  first_sentence, 
                  filler_sentence].join("\n\n")

      if File.exists?(full_filename)
        puts "Warning: File #{full_filename} already exists!"
      else
        puts "Creating file: #{full_filename}"
        f = File.open(file_path, "w+")
        f.puts(contents)
        f.close()
      end

    end

    def self.help method
      case method
      when :index
%Q{Create a new website project in the current directory.}

      when :post
%Q{Creates a new blog post with the date prepended to the file name.
Pass a quoted string, capitalized, for the title of the post.}

      else
        "No help available for #{method}."

      end
    end
  end

end

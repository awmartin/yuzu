
module Yuzu::Command

  # Create produces a new content such as a new yuzu website project or new blog post.
  class Create < ConfiglessCommand
    def initialize(args)
      @args = args
    end

    def index
      puts "Creating a new yuzu project in this directory."

      #['_templates', 'js', 'css', 'blog', 'img'].each do |folder|
      #  FileUtils.mkdir(folder)
      #end

      # The directory the user is running yuzu in.
      destination_dir = Dir.pwd

      ["_templates", "js", "css", "img", "_sass"].each do |source_dir|
        all_sources = File.join(File.dirname(__FILE__), "..", "..", "..", "resources", source_dir)
        FileUtils.cp_r(all_sources, destination_dir)
      end

      ["config", "samples"].each do |folder|
        rel_path = File.join(File.dirname(__FILE__), "..", "..", "..", "resources", folder, "*")
        FileUtils.cp_r(Dir[rel_path], File.join(destination_dir, "config"))
      end

      puts
      puts "Remember to edit yuzu.yml to set your site settings, preview path, and remote host."
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
      end
    end
  end

end

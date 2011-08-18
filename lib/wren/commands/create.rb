module Wren::Command
  class Create < Base
    def index
      puts `compass create . --using blueprint --syntax sass`
      puts `mkdir _templates`
      destination_dir = Dir.pwd
      Dir["#{File.dirname(__FILE__)}/../templates/*"].each do |template|
        file = File.basename(template)
        
        puts "Copying #{file}..."
        
        if file[0].chr == "_"
          FileUtils.copy( "#{template}", "#{destination_dir}/_templates/#{file}")
        else
          FileUtils.copy( "#{template}", "#{destination_dir}/#{file}")
        end
        
      end
      puts
      puts "Remember to edit wren.yml to set your site settings, preview path, and remote host."
    end
    
    # args[1] is a string that contains the blog title
    # Creates a new post with the lower-case title, TITLE() directive, and prefix publication date.
    def post
      t = Time.now
      day_str = sprintf "%02d", t.day
      mon_str = sprintf "%02d", t.month
      year_str = sprintf "%04d", t.year
      base_filename = @args.first.gsub(" ", "-").downcase
      
      full_filename = "#{year_str}-#{mon_str}-#{day_str}-#{base_filename}.haml"
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
      contents = "TITLE(#{post_title})\n\n%p #{first_sentence}\n\n%p #{filler_sentence}\n\n"
      
      
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
      when :default
        "Create a new website project in the current directory. This creates a new sass project then generates a new configuration file."
      when :post
        "Creates a new blog post with the date prepended to the file name. Pass a quoted string, capitalized, for the title of the post."
      else
      end
    end
  end
end

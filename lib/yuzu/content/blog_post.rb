
module Yuzu::Content
  class BlogPost
    def initialize(postname, config)
      @postname = postname
      @filename = postname.dasherize.downcase
      @config = config
    end

    def deliver!
      date = Time.now.strftime("%Y-%m-%d")
      full_filename = "#{date}-#{@filename}.md"

      file_path = File.join(@config.blog_dir, full_filename)

      if File.exists?(file_path)
        $stderr.puts "Warning: File #{@filename} already exists!"

      else
        $stderr.puts "Creating file: #{@filename}"

        File.open(file_path, "w+") do |f|
          f.puts(contents)
        end

      end
    end

    def contents
      return %Q{# #{@postname}

The title of this post is #{@postname}.

Lorem ipsum dolor sit amet, consectetur adipisicing elit, 
sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim 
ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip 
ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate 
velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat 
cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id 
est laborum.
}
    end
  end

end

require 'content/sample_project'
require 'content/blog_post'

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

    # Produces a new blog post with the name given on the command line.
    def post
      # TODO re-enable blog post creation. Requires a config file.
      #if @args.length > 0
      #  new_post = BlogPost.new(@args.first, @config)
      #else
      #  @stderr.puts 'create:post requires a filename. Try yuzu create:post "Post Title Here"'
      #end
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

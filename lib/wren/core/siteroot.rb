require 'core/website_folder'

Dir["#{File.dirname(__FILE__)}/../generators/*"].each { |c| require c }

module Wren::Core
  class SiteRoot < WebsiteFolder
    include Wren::Generators

    attr_reader :config
    def initialize(wren_config)
      @config = wren_config
      @path = @config.pwd
      @parent = nil
      @kind = :folder

      generate!
    end

    def name
      @config.site_name
    end

    # Given a Path, return the WebsiteFile or WebsiteFolder corresponding to the Path.
    def find_file_by_path(path)
      path_elements = path.relative.split(File::SEPARATOR)

      parent = self
      path_elements.each do |element|
        child = parent.get_child_by_rootname(element)
        return nil if child.nil?
        parent = child
      end

      return parent
    end

    def generators
      Generator.generators
    end

    # Process all the generators to make all the new files required from things like pagination of
    # catalogs and new index files.
    def generate!
      generators.each_pair do |name, generator|
        v = Visitor.new(generator.visitor_filter)

        v.traverse(self) do |node|
          if generator.should_generate?(node)
            generator.generate!(node)
          end
        end
      end
    end
  end

end


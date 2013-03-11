require 'helpers/import'
import 'helpers/path'
import 'yuzu/core/website_folder'

Dir.glob(File.join(File.dirname(__FILE__), "..", "generators", "*")).each do |c|
  require c
end

module Yuzu::Core
  class SiteRoot < WebsiteFolder
    include Yuzu::Generators

    attr_reader :config
    def initialize(yuzu_config, path=nil)
      @config = yuzu_config
      @path = path.nil? ? Path.pwd : Path.new(path)
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


require 'haml'
require 'helpers/path'

module Wren::Core
  class Template
    include Helpers

    # TODO Make this part of a module-level config.
    @@template_dir = Path.new("_templates")

    # template_name -- String. The filename of the template, e.g. _gallery.haml
    def initialize(template_name)
      @template_name = template_name
    end

    def path
      @@template_dir + @template_name
    end

    def contents
      @contents ||= get_contents
    end

    def exists?
      path.exists?
    end

    def get_contents
      if exists?
        f = File.open(path.absolute, 'r')
        contents = f.read
        f.close
        return contents
      else
        ""
      end
    end

    def render(website_file, data={})
      ""
    end
  end


  class HamlTemplate < Template
    def options
      {:format => :html5}
    end

    def engine
      @engine ||= Haml::Engine.new(contents, options)
    end

    def locals(website_file)
      {
        :post => website_file.properties,
        :config => website_file.config
      }
    end

    def render(website_file, data={})
      engine.render(
        TemplateMethods.new(website_file.root),
        locals(website_file).merge(data)
      )
    end
  end


  # The root object that contains functions that can be called from inside the Haml template.
  class TemplateMethods
    def initialize(siteroot)
      @siteroot = siteroot
    end

    def insert_raw_file(filename)
      insert_contents(filename, :raw_contents)
    end

    def insert_rendered_contents(filename)
      insert_contents(filename, :rendered_contents)
    end

    def insert_contents(filename, method=:raw_contents)
      path = Helpers::Path.new(filename)
      return (Html::Comment.new << "File #{filename} not found.") if not path.exists?

      website_file = @siteroot.find_file_by_path(path)

      if not website_file.nil?
        website_file.send(method)

      else

        f = File.open(filename, "r")
        contents = f.read
        f.close

        return contents if method == :raw_contents
        Wren::Translators::Translator.translate(contents, path.extension)

      end
    end

  end
end


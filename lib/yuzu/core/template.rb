require 'haml'
require 'helpers/path'

module Yuzu::Core
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

    def exists?
      path.exists?
    end

    def fallback_path
      # TODO Configure fallbacks in a more general way.
      if @template_name[0].chr == "_"
        @@template_dir + "_block.haml"
      else
        @@template_dir + "generic.haml"
      end
    end

    def fallback_exists?
      fallback_path.exists?
    end

    def contents
      @contents ||= get_contents
    end

    def get_contents
      tr = get_template_contents(path)
      tr.nil? ? get_template_contents(fallback_path) : tr
    end

    def get_template_contents(file_path)
      if file_path.exists?
        f = File.open(file_path.absolute, 'r')
        contents = f.read
        f.close
        contents
      else
        $stderr.puts "WARNING: Couldn't find template #{file_path}"
        nil
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
        Yuzu::Translators::Translator.translate(contents, path.extension)

      end
    end

    def format_date(raw_date)
      if not raw_date.is_a?(String) and not raw_date.is_a?(Time)
        return raw_date
      end

      if raw_date.is_a?(String)
        raw_date = Time.parse(raw_date)
      end

      date = raw_date.strftime("%Y-%m-%d")

      months = {
        "01" => "January",
        "02" => "February",
        "03" => "March",
        "04" => "April", 
        "05" => "May",
        "06" => "June",
        "07" => "July",
        "08" => "August", 
        "09" => "September",
        "10" => "October",
        "11" => "November",
        "12" => "December"
      }

      year, month, day = date.split("-")[0..2]
      month = months[month]

      "#{year} #{month} #{day}"
    end

  end
end


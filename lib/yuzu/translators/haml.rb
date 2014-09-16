require 'haml'

require 'helpers/import'
import 'yuzu/translators/base'

module Yuzu::Translators

  class HamlTranslator < Translator
    def extensions
      %w(.haml)
    end

    def options
      {}
    end

    def translate(contents)
      engine ||= Haml::Engine.new(contents, options)
      rendered = engine.render()
      rendered = rendered.gsub("<p><noscript></p>", "<noscript>").gsub("<p></noscript></p>", "</noscript>")
      rendered.gsub(/\n\s*<\/code>/, "</code>").gsub(/<code>(?!\s)/, "<code>  ")
    rescue => e
      $stderr.puts "Exception while processing Haml contents:"
      $stderr.puts contents
      raise StandardError
    end

    def extract_title_from_contents(contents)
      m = contents.match(h1_regex)
      return m.nil? ? nil : m[0].sub("%h1.", "").strip
    end

    def h1_regex
      Regexp.new('^%h1.\s+.*?\n')
    end
  end
  Translator.register(:haml => HamlTranslator)

end



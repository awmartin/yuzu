begin
  require 'RedCloth'
rescue LoadError
end

require 'helpers/import'
import 'helpers/system_checks'
import 'yuzu/translators/base'

module Yuzu::Translators

  class TextileTranslator < Translator
    def extensions
      %w(.text .textile)
    end

    def translate(contents)
      if SystemChecks.gem_available?("RedCloth")
        RedCloth.new(contents).to_html
      else
        contents
      end
    end

    def extract_title_from_contents(contents)
      m = contents.match(h1_regex)
      m.nil? ? nil : m[0].sub("h1.", "").strip
    end

    def h1_regex
      Regexp.new(/^h1\.\s+.*?\n/)
    end
  end
  Translator.register(:textile => TextileTranslator)

end



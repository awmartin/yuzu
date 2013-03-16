require 'kramdown'

require 'helpers/import'
import 'yuzu/translators/base'

module Yuzu::Translators

  class MarkdownTranslator < Translator
    def extensions
      %w(.md .mdown .mkd .markdown .markd)
    end

    def translate(contents)
      rendered = Kramdown::Document.new(contents).to_html
      rendered = rendered.gsub("<p><noscript></p>", "<noscript>").gsub("<p></noscript></p>", "</noscript>")
      rendered.gsub(/\n\s*<\/code>/, "</code>").gsub(/<code>(?!\s)/, "<code>  ")
    end

    def extract_title_from_contents(contents)
      m = contents.match(/^#\s+.*?\n/)
      return m.nil? ? nil : m[0].sub("#", "").strip
    end
  end
  Translator.register(:markdown => MarkdownTranslator)

end



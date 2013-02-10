
module Yuzu::Translators

  class PlaintextTranslator < Translator
    def extensions
      %(txt text)
    end

    def translate(contents)
      contents
    end
  end
  Translator.register(:plaintext => PlaintextTranslator)

end


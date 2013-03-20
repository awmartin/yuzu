require 'helpers/import'
import 'yuzu/translators/base'

module Yuzu::Translators

  class PlaintextTranslator < Translator
    def extensions
      %w(.txt)
    end
  end
  Translator.register(:plaintext => PlaintextTranslator)

end


# Translators translate one markup language to another, e.g. markdown to html.

module Yuzu::Translators
  include Yuzu::Registrar

  class Translator < Register
    @@translators = {}
    def self.registry
      :translators
    end
    def self.translators
      @@translators
    end

    def self.translate(contents, file_extension)
      filetype = identify_filetype(file_extension)
      if not filetype.nil?
        Translator.translators[filetype].translate(contents)
      else
        contents
      end
    end

    def self.can_translate?(website_file)
      source_extension = website_file.path.extension
      # TODO map source -> output extensions, e.g. haml-to-xml, etc.
      #target_extension = website_file.extension
      filetype = identify_filetype(source_extension)
      not filetype.nil?
    end

    def self.identify_filetype(file_extension)
      Translator.translators.each_pair do |filetype, translator|
        return filetype if translator.translates?(file_extension)
      end
      return nil
    end

    def self.filetypes
      Translator.translators.keys
    end

    def translates?(file_extension)
      extensions.include?(file_extension)
    end

    def extensions
      []
    end

    def translate(contents)
      contents
    end
  end

end


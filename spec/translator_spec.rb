
require 'spec_helper'

describe Yuzu::Translators::Translator do
  include TestMocks

  describe "(registration)" do
    include_examples "registries", Yuzu::Translators::Translator.translators, "translators"
  end
end



require 'spec_helper'

describe Yuzu::Generators::Generator do
  include TestMocks

  describe "(registration)" do
    include_examples "registries", Yuzu::Generators::Generator.generators, "generators"
  end
end


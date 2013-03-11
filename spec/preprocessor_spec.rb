
require 'spec_helper'

describe Yuzu::PreProcessors::PreProcessor do
  include TestMocks

  describe "(registration)" do
    include_examples "registries", Yuzu::PreProcessors::PreProcessor.preprocessors, "preprocessors"
  end
end


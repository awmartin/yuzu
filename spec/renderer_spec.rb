
require 'spec_helper'

describe Yuzu::Renderers::Renderer do
  include TestMocks

  describe "(registration)" do
    include_examples "registries", Yuzu::Renderers::Renderer.renderers, "renderers"
  end
end


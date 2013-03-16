require 'spec_helper'
require 'set'

describe Yuzu::Filters::Filter do
  include TestMocks

  describe "(registration)" do
    include_examples "registries", Yuzu::Filters::Filter.filters, "filters"
  end
end

describe Yuzu::Filters::CatalogFilter do
  include TestMocks

  before do
    @blog_index = test_site.blog_folder.get_child_by_basename("index")
    @catalog_test_folder = test_site.get_child_by_rootname("catalogs")
  end

  describe "(values)" do
    # Looks for the title of each blog post inserted as a <h2> tag, sepcified in
    # _templates/_block.haml.
    it "should have generated the correct posts" do
      rendered_contents = @blog_index.rendered_contents

      regex = Regexp.new('<h2[^>]*?>([\w\W]*?)</h2>')
      matches = rendered_contents.scan(regex)

      titles = matches.collect {|m| m[0].to_s}
      Set.new(titles).should == Set.new(["Blog Post 1", "Blog Post 2"])
    end
  end

end


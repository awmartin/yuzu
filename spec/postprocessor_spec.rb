
require 'spec_helper'
require 'set'

describe Yuzu::PostProcessors::PostProcessor do
  include TestMocks

  describe "(registration)" do
    include_examples "registries", Yuzu::PostProcessors::PostProcessor.postprocessors, "postprocessors"
  end
end

describe Yuzu::PostProcessors::AllCategoriesPostProcessor do
  include TestMocks

  before do
    @test_file = test_site.get_child_by_basename("index")
  end

  describe "(values)" do
    it "should produce categories from the entire site" do
      all_category_names = @test_file.all_categories.collect {|cat| cat.name}
      test_categories = ["blog-category-1", "blog-category-2", "category-1", "category-2", "category-3"]
      Set.new(all_category_names).should == Set.new(test_categories)
    end
  end
end

# Blog Categories
describe Yuzu::PostProcessors::BlogCategoriesPostProcessor do
  include TestMocks

  before do
    @test_file = test_site.get_child_by_basename("index")
  end

  describe "(values)" do
    it "should produce categories from the blog only" do
      blog_category_names = @test_file.blog_categories.collect {|cat| cat.name}
      Set.new(blog_category_names).should == Set.new(["blog-category-1", "blog-category-2"])
    end
  end
end


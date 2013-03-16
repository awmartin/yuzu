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


describe Yuzu::Filters::CategoriesFilter do
  include TestMocks

  before do
    @home = test_site.get_child_by_filename("index.md")
    @blog_post = test_site.get_child_by_rootname("blog").get_child_by_filename("blog_post_1.md")
  end

  def home_categories
    @home.categories.sort
  end

  def home_category_names
    home_categories.collect {|cat| cat.name}
  end

  def blog_post_categories
    @blog_post.categories.sort
  end

  it "should collect the proper categories from a page" do
    Set.new(home_category_names).should == Set.new(['category-1', 'category-2'])
  end

  it "should create blog categories with the correct paths" do
    blog_post_categories[0].path.should == Helpers::Path.new("blog/blog-category-1")
  end
end

describe Yuzu::Filters::PostTitleFilter do
  include TestMocks

  before do
    @home = test_site.get_child_by_filename("index.md")
    @blog = test_site.get_child_by_rootname("blog").get_child_by_filename("index.md")
    @page = test_site.get_child_by_filename("page1.md")
    @pages_folder_index = test_site.get_child_by_rootname("pages").get_child_by_filename("index.md")
    @generic_page = test_site.get_child_by_rootname("pages").get_child_by_filename("generic-mock-website-page.md")
    @dated_page = test_site.get_child_by_rootname("pages").get_child_by_filename("2013-03-16-dated-mock-website-page.md")
  end

  it "should extract the correct title from home page" do
    @home.post_title.should == "Home"
  end

  it "should extract the correct title from index files" do
    @pages_folder_index.post_title.should == "Pages"
  end

  it "should extract the correct title from index files" do
    @blog.post_title.should == "Blog Index"
  end

  it "should extract the correct title from markdown files" do
    @page.post_title.should == "Test Page 1"
  end

  it "should extract the correct title from filenames" do
    @generic_page.post_title.should == "Generic Mock Website Page"
  end

  it "should extract the correct title from a filename with date" do
    @dated_page.post_title.should == "Dated Mock Website Page"
  end
end


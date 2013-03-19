require 'spec_helper'

require 'helpers/import'
import 'yuzu/core/visitor'
import 'helpers/path'

describe Yuzu::Generators::Generator do
  include TestMocks

  describe "(registration)" do
    include_examples "registries", Yuzu::Generators::Generator.generators, "generators"
  end
end

describe Yuzu::Generators::CategoryFoldersGenerator do
  include TestMocks

  before do
    @home = test_site.get_child_by_filename('index.md')
    @blog_folder = test_site.blog_folder
  end

  def blog_categories
    @home.blog_categories
  end

  def category_folders
    category_folders = []
    category_folders_only = proc {|node| node.is_a?(Yuzu::Generators::GeneratedCategoryFolder)}

    v = Yuzu::Core::Visitor.new(category_folders_only)
    v.traverse(test_site.blog_folder) do |folder|
      category_folders.push(folder)
    end

    category_folders
  end

  it "should generate category folders with the correct paths" do
    category_folders[0].path.absolute.should == Helpers::Path.new('blog/blog-category-1').absolute
  end

  it "should generate the correct category folders for the blog folder" do
    category_folder_names = Set.new(blog_categories.collect {|cat| cat.name})
    collected_category_folder_names = Set.new(category_folders.collect {|folder| folder.category.name})

    collected_category_folder_names.should == category_folder_names
  end
end

describe Yuzu::Generators::PaginateGenerator do
  include TestMocks

  before do
    @catalogs_folder = test_site.get_child_by_rootname("catalogs")
    @pagination_default = @catalogs_folder.get_child_by_filename("pagination_default.md")
  end

  it "should generate the proper number of pages" do
    num_siblings_generated = @pagination_default.stash[:paginated_siblings]
    num_siblings_generated.length.should_not == 0

    catalog_to_be_paginated = @pagination_default.stash[:source_catalog]
    catalog_to_be_paginated.should_not be_nil

    catalog_to_be_paginated.num_pages.should == (num_siblings_generated.length + 1)
  end

  # The testing template _block.haml places titles of pages as h2 tags. This will extract all of
  # them from the rendered_contents of a WebsiteFile.
  #
  # @param [WebsiteFile] website_file The file containing a rendered Catalog to test.
  # @return [Array of Strings] An array of all the <h2></h2> tag contents of the file.
  def get_h2_titles_from_rendered_contents(website_file)
    title_regex = Regexp.new('<h2[^>]*?>([\w\W]*?)</h2>')
    title_matches = website_file.rendered_contents.scan(title_regex)
    title_matches.collect {|m| m[0].to_s}
  end

  # Return the paths of the files on disk meeting the given requirements from the pagination-pages
  # folder.
  def get_page_paths_from_disk(number_of_pages, reversed=false, offset=0)
    pages = Dir.glob(File.join(File.dirname(__FILE__), "content", "pagination-pages", "page*.md"))

    if reversed
      pages[(pages.length - number_of_pages)..pages.length].reverse
    else
      pages[offset...(offset + number_of_pages)]
    end
  end

  # Open the given Markdown file and return the # ... title from its contents.
  #
  # @param [String] page_path An absolute path on disk to the file to open.
  # @return [String] The contents of the <h1> equivalent tag in Markdown.
  def extract_title_from_page(page_path)
    f = File.open(page_path)
    file_contents = f.read
    f.close

    markdown_translator = Yuzu::Translators::Translator.translators[:markdown]
    markdown_translator.extract_title_from_contents(file_contents)
  end

  it "should sort by reversed post date by default" do
    titles = get_h2_titles_from_rendered_contents(@pagination_default)

    last_pages = get_page_paths_from_disk(5, true)
    page_titles = last_pages.collect {|path| extract_title_from_page(path)}

    titles.should == page_titles
  end

  it "should sort by post title properly" do
    pagination_sort_by_post_title = \
      @catalogs_folder.get_child_by_filename("pagination_sort_by_post_title.md")

    titles = get_h2_titles_from_rendered_contents(pagination_sort_by_post_title)

    page_paths = get_page_paths_from_disk(5)
    page_titles = page_paths.collect {|path| extract_title_from_page(path)}

    titles.should == page_titles
  end

end


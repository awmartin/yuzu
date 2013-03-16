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

  it "should generated category folders with the correct paths" do
    category_folders[0].path.absolute.should == Helpers::Path.new('blog/blog-category-1').absolute
  end

  it "should generate the correct category folders for the blog folder" do
    category_folder_names = Set.new(blog_categories.collect {|cat| cat.name})
    collected_category_folder_names = Set.new(category_folders.collect {|folder| folder.category.name})

    collected_category_folder_names.should == category_folder_names
  end
end


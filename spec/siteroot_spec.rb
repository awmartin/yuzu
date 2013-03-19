require 'spec_helper'
require 'set'

describe Yuzu::Core::SiteRoot do
  include TestMocks

  it "should have no children that aren't real children" do
    all_are_children = true

    v = Yuzu::Core::Visitor.new
    v.traverse(test_site) do |node|
      all_are_children &&= test_site.path.is_descendant?(node.path)
    end

    all_are_children.should be_true
  end

  it "should properly identify the blog folder" do
    blog_folder = test_site.get_child_by_rootname("blog")
    correct_blog_folder_path = Helpers::Path.new(config.blog_dir)

    blog_folder.path.should == correct_blog_folder_path
  end

  it "should properly identify the blog name" do
    test_site.blog_folder.path.name.should == "blog"
  end

  it "should have a blog folder with the correct number of children" do
    blog_folder = test_site.get_child_by_rootname("blog")
    blog_index = blog_folder.get_child_by_filename("index.md")

    files = Dir.glob(File.join(File.dirname(__FILE__), "content", "blog", "*"))

    num_blog_categories = blog_index.blog_categories.length
    num_predicted_children = num_blog_categories + files.length

    blog_folder.children.length.should == num_predicted_children
  end
end


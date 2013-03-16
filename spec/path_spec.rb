
require 'spec_helper'
require 'set'

require 'helpers/import'
import 'helpers/path'

describe Helpers::Path do
  it "should produce the correct absolute path relative to the specified local path" do
    p1 = Helpers::Path.new("content/catalogs/index.md")
    current_test_dir = Helpers::Path.local_root
    p1.absolute.should == File.join(current_test_dir, "content/catalogs/index.md").to_s
  end

  it "should produce the correct absolute path when given a root override" do
    p = Helpers::Path.new("content/catalogs/index.md", root="/tmp/root")
    p.absolute.should == File.join(File::SEPARATOR, "tmp", "root", "content", "catalogs", "index.md").to_s
  end

  it "should calculate the correct sum of two relative paths" do
    p1 = Helpers::Path.new("hello")
    p2 = Helpers::Path.new("doctor")
    sum = (p1 + p2).to_s
    correct_sum = File.join("hello", "doctor").to_s

    sum.should == correct_sum
  end

  it "should produce a relative path when adding empty to relative" do
    p1 = Helpers::Path.new("")
    p2 = Helpers::Path.new("content/catalogs/index.md")
    sum = (p1 + p2).to_s
    correct_sum = "content/catalogs/index.md"
    sum.should == correct_sum
  end

  it "should recognize a descendant" do
    p1 = Helpers::Path.new("content")
    p2 = Helpers::Path.new("content/blog")
    p1.is_descendant?(p2).should == true
  end

  it "should recognize non-descendants" do
    p1 = Helpers::Path.new("content/catalogs")
    p2 = Helpers::Path.new("content/blog")
    p1.is_descendant?(p2).should == false
  end

  it "should recognize descendants of its parent" do
    p1 = Helpers::Path.new("content/catalogs")
    p2 = Helpers::Path.new("content/blog")
    p1.parent.is_descendant?(p2).should == true
  end

  it "should resolve .. properly" do
    p1 = Helpers::Path.new("content/catalogs")
    p2 = Helpers::Path.new("content/../content/catalogs")
    p1.should == p2
  end

  it "should equal its absolute equivalent" do
    p1 = Helpers::Path.new("catalogs")
    absolute_path = File.join(File.dirname(__FILE__), "content", "catalogs")
    p2 = Helpers::Path.new(absolute_path)
    p1.should == p2
  end
end


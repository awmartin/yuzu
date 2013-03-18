require 'spec_helper'
require 'set'


describe Yuzu::Core::WebsiteFolder do
  include TestMocks

  def has_methods_defined?(names)
    has_all = true
    names.each do |name|
      has_all &&= @test_file.methods.include?(name.to_s)
    end
    has_all
  end

  it "should have only one copy of each child WebsiteFile" do
    children_counts = {}

    test_site.children.each do |child|
      key = child.path.absolute.to_s
      if children_counts.has_key?(key)
        children_counts[key] += 1
      else
        children_counts[key] = 1
      end
    end

    total = 0
    children_counts.each_pair do |key, count|
      total += count
    end

    total.should == test_site.children.length
  end
end


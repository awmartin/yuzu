require 'spec_helper'

describe Yuzu::Core::WebsiteFile do
  before do
    @config_hash = YAML.load_file('content/config/yuzu.yml')
    @config = Yuzu::Core::Config.new(@config_hash, "preview")
    @siteroot = Yuzu::Core::SiteRoot.new(@config, 'content')
    @test_file = @siteroot.get_child_by_basename("index")
  end

  def has_methods_defined?(names)
    has_all = true
    names.each do |name|
      has_all &&= @test_file.methods.include?(name.to_s)
    end
    has_all
  end

  describe "(creation)" do
    it "should exist as a child of the siteroot" do
      @test_file.should_not be_nil
    end

    it "should be an index" do
      @test_file.should be_index
    end

    it "should be the home page" do
      @test_file.should be_home
    end
  end

  describe "(registration)" do
    it "should have a method for each registered filter" do
      filter_names = Yuzu::Filters::Filter.filters.keys
      has_methods_defined?(filter_names).should == true
    end

    it "should have a method for each registered renderer" do
      renderer_names = Yuzu::Renderers::Renderer.renderers.keys
      has_methods_defined?(renderer_names).should == true
    end

    it "should have a method for each registered postprocessor" do
      postprocessor_names = Yuzu::PostProcessors::PostProcessor.postprocessors.keys
      has_methods_defined?(postprocessor_names).should == true
    end
  end

  describe "(filter values)" do
    it "should have the correct post title" do
      @test_file.post_title.should == "Index File For Testing"
    end

    it "should have the correct extension" do
      @test_file.extension.should == ".html"
    end

    it "should have the correct linkroot" do
      @test_file.linkroot.should == "/tmp/yuzu-test-preview"
    end

    it "should have the correct template" do
      @test_file.template.should == "test.haml"
    end

    it "should have two categories" do
      @test_file.categories.length.should == 2
    end

    it "should have the correct categories" do
      @test_file.categories.collect {|cat| cat.name}.sort.should == ["category1", "category2"]
    end

    it "should have the correct sidebar content" do
      @test_file.sidebar.strip.should == "<p>sidebar content</p>"
    end
  end

end


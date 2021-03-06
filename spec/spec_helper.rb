begin
  require "rspec"
rescue LoadError
  require "spec"
end

require 'set'
require 'pathname'
require 'helpers/import'
import 'yuzu'
import 'helpers/path'

# Set the Path root directory to the root of the sample content.
SITE_DIR = Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), "content")))
Helpers::Path.local_root = SITE_DIR

module TestMocks
module_function

  def parent_folder
    File.expand_path(File.dirname(__FILE__))
  end

  def get_registered_files_for(registry_name)
    registry_path = File.expand_path(File.join(parent_folder, "..", "lib", "yuzu", registry_name, "*.rb"))
    registry_files = Dir.glob(registry_path).reject {|f| f.end_with?("base.rb")}
    registry_symbols = registry_files.collect {|f| File.basename(f).gsub(".rb", "").to_sym}

    Set.new(registry_symbols)
  end

  @@test_site = nil
  def test_site
    @@test_site ||= get_test_site
  end

  def config
    @@config ||= get_config
  end

  def get_config
    config_path = File.expand_path(File.join(parent_folder, "content", "config", "yuzu.yml"))

    config_hash = YAML.load_file(config_path)
    config = Yuzu::Core::Config.new(config_hash, "preview")
    config
  end

  def get_test_site
    Yuzu::Core::SiteRoot.new(config)
  end

end

shared_examples "registries" do |registered, registry_name|
  it "should have registered all the files successfully" do
    should_be_registered = TestMocks.get_registered_files_for(registry_name)
    Set.new(registered.keys).should == should_be_registered
  end
end


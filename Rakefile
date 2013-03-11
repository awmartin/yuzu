require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
require File.expand_path('./lib/yuzu/version.rb')
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "yuzu"
  gem.homepage = "http://github.com/awmartin/yuzu"
  gem.license = "MIT"
  gem.summary = %Q{A blog-aware, static-website generator that converts a folder of text files and images into an HTML5 website.}
  gem.description = %Q{Yuzu is a blog-aware, static-website (and PDF) generator that converts a folder of text files and images into multiple forms and publishes them to an FTP server, file system, or Amazon Simple Storage Service (S3). It is extensible and designed to function with minimal setup.}
  gem.email = "william.martin@anomalus.com"
  gem.authors = ["William Martin"]
  gem.executables = ['yuzu']
  gem.version = Yuzu::Version::STRING

  gem.add_dependency 'kramdown', '>= 0.13.7'
  gem.add_dependency 'haml', '>= 3.1.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new

require 'yard'
YARD::Rake::YardocTask.new do |t|
  #t.files   = ['lib/**/*.rb', OTHER_PATHS]
  t.options = ['t', 'default', '-p', 'resources/yard', "--markup", "markdown"]
end

require 'rspec'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |config|
  #config.rcov = true
end

# require 'rake/testtask'
# Rake::TestTask.new(:test) do |test|
#   test.libs << 'lib' << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
# end
# 
# require 'rcov/rcovtask'
# Rcov::RcovTask.new do |test|
#   test.libs << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
# end
# 
# task :default => :test
# 
# require 'rake/rdoctask'
# Rake::RDocTask.new do |rdoc|
#   version = File.exist?('VERSION') ? File.read('VERSION') : ""
# 
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title = "yuzu #{version}"
#   rdoc.rdoc_files.include('README*')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

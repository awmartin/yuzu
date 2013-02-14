#!/usr/bin/env ruby -wKU


$LOAD_PATH.unshift(File.dirname(__FILE__) + '/yuzu')
$: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

#require File.expand_path('../yuzu/version.rb', __FILE__)

module Yuzu
  ROOT = File.expand_path(File.dirname(__FILE__))
end

Dir.glob(File.join(Yuzu::ROOT, 'yuzu', '*')).each do |path|
  if File.directory?(path)

    Dir.glob(File.join(path, "*.rb")).each do |file|
      require file
    end

  else
    require path

  end
end


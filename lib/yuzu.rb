#!/usr/bin/env ruby -wKU


$LOAD_PATH.unshift(File.dirname(__FILE__) + '/yuzu')
$: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))


module Yuzu
  ROOT = File.expand_path(File.dirname(__FILE__))
end

Dir.glob(File.expand_path(File.join(Yuzu::ROOT, 'yuzu', '*'))).each do |path|

  if File.directory?(path)
    # Require all the files in the yuzu directories, e.g. yuzu/command/*
    Dir.glob(File.expand_path(File.join(path, "*.rb"))).each do |file|
      require File.expand_path(file)
    end

  else
    # Require all top-level files.
    require File.expand_path(path)

  end
end


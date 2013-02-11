
module Yuzu
  module Version
    MAJOR = 0
    MINOR = 2
    PATCH = 0
    BUILD = "build"
  end

  VERSION_STRING = [Version::MAJOR, Version::MINOR, Version::PATCH].compact.join(".")
end


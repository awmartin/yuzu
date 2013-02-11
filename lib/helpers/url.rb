# Url holds an abstraction for web URLs, closely tied to the Path objects. This aids in translating
# on-disk paths to URLs for links.
module Helpers

  class Url
    # Create a new Url object.
    #
    # @param [String, Path] url_path The root path of the Url, from the file system, with the
    #   appropriate extension in place ideally.
    # @param [String] prefix A prefix to add to the front of the url. This usually consists of the
    #   root common path on the server like http://domain.com/blah
    def initialize(url_path, prefix=nil)
      if url_path.is_a?(Path)
        @path = url_path

      elsif url_path.is_a?(String)
        @path = Path.new(url_path)

      elsif url_path.is_a?(Url)
        @path = url_path.path

      else
        raise "Url must be initialized with a String, Url, or Path instance."

      end

      @prefix = prefix
    end

    attr_accessor :path

    def + (other)
      if other.is_a?(String)
        Url.new(@path + other, prefix=@prefix)

      elsif other.is_a?(Url)
        Url.new(@path + other.path.relative, prefix=@prefix)

      elsif other.is_a?(Path)
        Url.new(@path + other.relative_path, prefix=@prefix)

      else
        raise "Url + accepts String, Path, and Url instances."

      end
    end

    def to_s
      full
    end

    def full(new_extension=nil)
      new_extension.nil? ? join(@prefix, @path) : join(@prefix, @path.with_extension(new_extension))
    end

    # Join a set of paths together
    def join(prefix, path, suffix=nil)
      root = prefix.nil? ? path.relative : prefix + "/" + path.relative
      suffix.nil? ? root : root + "/" + suffix
    end
  end

end


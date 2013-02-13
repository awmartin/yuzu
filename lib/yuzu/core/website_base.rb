require 'helpers/path'

module Yuzu::Core
  class WebsiteBase
    include Helpers

    attr_reader :path, :parent, :kind

    def initialize(path, parent)
      raise "WebsiteBase not initialized with a Path object." if not path.is_a?(Path)

      @path = path
      raise "@path is nil for #{self}" if @path.nil?
      @parent = parent
      @kind = nil
      @stash = {}
    end

    def == (other)
      return false if not other.is_a?(WebsiteBase)
      return @path == other.path
    end

    def name
      @path.basename
    end

    def root
      @root ||= (@parent.nil? ? self : @parent.root)
    end

    def root?
      root == self
    end

    def blog_folder
      @@blog ||= root.find_file_by_path(Path.new(config.blog_dir))
    end

    def in_blog?
      blog_folder.nil? ? false : blog_folder.is_child?(self)
    end

    def is_blog?
      self == blog_folder or (index? and self.path.dirname == blog_folder.path.dirname)
    end

    def index?
      false
    end

    def config
      @parent.config
    end

    def file?
      @kind == :file
    end

    def folder?
      @kind == :folder
    end

    def children
      nil
    end

    def processable?
      @processable ||= is_processable?
    end

    def is_processable?
      return false if folder?
      config_says = config.processable?(@path)
      translators_say = Yuzu::Translators::Translator.can_translate?(self)
      config_says and translators_say
    end

    def resource?
      return false if folder?
      config.resource?(@path)
    end

    def image?
      return false if folder?
      config.image?(@path)
    end

    def asset?
      return false if folder?
      config.asset?(@path)
    end

    def hidden?
      return false if root?
      @parent.hidden? or @path.rootname[0].chr == "_"
    end

    def config
      @parent.config
    end

    def link_to_self(attr={})
      Html::Link.new({:href => link_url}.merge(attr)) << name
    end

    def link_url
      @link_url ||= get_link_url
    end

    def get_link_url
      folder? ? (currentpath + "index.html") : (currentpath + output_filename).full
    end

    def remote_path
      @remote_path ||= get_remote_path
    end

    def get_remote_path
      if processable?
        tr = file? ? @path.with_extension(extension) : @path
        if tr == @path
          raise "Remote path and source path are the same! Got #{tr} and #{@path}."
        end
        tr
      else
        @path
      end
    end

    def default_stash
      {
        :generated_siblings => [],
        :catalog => nil
      }
    end

    # Enables other processes to add imbue this node with information.
    def stash(kwds={})
      @stash = default_stash if @stash.nil?
      kwds.empty? ? @stash : @stash.update(kwds)
    end

    def generated?
      false
    end

  end
end


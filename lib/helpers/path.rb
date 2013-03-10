require 'pathname'

module Helpers

  # Path enables more intelligent handling of disk paths. Using Pathname as a foundation, Path
  # instances can detect parent/child relationships, handle extension and name manipulations natively,
  # and automate absolute/relative path distinctions.
  class Path
    attr_reader :pathname

    def self.join(path1, path2)
      # TODO This is rather expensive. Make the join more efficient.
      Path.new(path1).join(Path.new(path2))
      #Pathname.new(path1).join(Pathname.new(path2)).to_s
    end

    def initialize(*args)
      if args.length > 1
        path = File.join(*args)
      else
        path = args[0]
      end

      if path.nil?
        @pathname = pwd

      elsif path.is_a?(Pathname)
        @pathname = path

      elsif path.is_a?(String)
        @pathname = Pathname.new(path)

      elsif path.is_a?(Path)
        @pathname = path.pathname

      else
        raise "Path#initialize didn't get a recognizable argument. Must be String, Pathname, or another Path."

      end
      raise "@pathname was nil" if @pathname.nil?

      if not @pathname.absolute?
        @pathname = @pathname.expand_path.relative_path_from(pwd)
      end
      @force_is_file = false
      @force_is_folder = false
    end

    def dup
      Path.new(@pathname.dup)
    end

    def make_file!
      @force_is_file = true
      @force_is_folder = false
    end

    def make_folder!
      @force_is_file = false
      @force_is_folder = true
    end

    def parent
      Path.new(@pathname.parent)
    end

    def markdown?
      [".md", ".mdown", ".mkd", ".markdown", ".markd"].include?(extension)
    end

    def plaintext?
      [".txt", ".text"].include?(extension)
    end

    def == (other)
      return false if not other.is_a?(Path)
      @pathname.expand_path == other.pathname.expand_path
    end

    def stringify
      "Path(#{absolute})"
    end

    def + (other)
      join(other)
    end

    def join(other)
      if other.is_a?(Path)
        Path.new(@pathname + other.pathname)
      else
        Path.new(@pathname + other)
      end
    end

    def get_child_by_pathname(pathname)
      return nil if children.nil?
      children.each do |c|
        return c if c.pathname == pathname
      end
      nil
    end

    def get_child_by_rootname(rootname)
      return nil if children.nil?
      children.each do |c|
        return c if c.rootname == rootname
      end
      nil
    end

    def get_child_by_basename(basename)
      return nil if children.nil?
      children.each do |c|
        return c if c.basename == basename
      end
      nil
    end

    def get_child_by_filename(filename)
      return nil if children.nil?
      children.each do |c|
        return c if c.filename == filename
      end
      nil
    end

    # Returns the name of the path
    #
    #     /path/to/file.md -- file.md
    #     /path/to/folder  -- folder
    #
    # @return [String]
    def name
      folder? ? @pathname.basename.to_s : filename.to_s
    end

    # Returns the base of the filename
    #
    #     /path/to/file.md -- file
    #     /path/to/folder  -- nil
    #
    # @return [String, nil]
    def basename
      folder? ? nil : @pathname.basename(extension).to_s
    end

    # Returns the actual filename
    #
    #     /path/to/file.md -- file.md
    #     /path/to/folder  -- nil
    #
    # @return [String, nil]
    def filename
      folder? ? nil : @pathname.basename.to_s
    end

    # Returns the directory of this Path
    #
    #     /path/to/file.md -- /path/to
    #     /path/to/folder  -- /path/to/folder
    #
    # @return [String]
    def dirname
      tr = folder? ? @pathname.to_s : @pathname.dirname.to_s
      tr == "." ? "" : tr
    end

    # Return the name of the last element of the Path
    #
    #     /path/to/file.md -- file.md
    #     /path/to/folder  -- folder
    #
    # @return [String]
    def rootname
      @pathname.basename.to_s
    end

    def extension
      @pathname.extname
    end

    # Return another Path but with the file's extension changed to the one passed in.
    def with_extension(new_extension)
      # This method should not return the same value, ever.
      if exists?
        file? ? Path.new(relative_path.dirname + (basename + new_extension)) : nil
      else
        Path.new(relative_path.dirname + (basename + new_extension))
      end
    end

    def add_suffix(suffix)
      file? ? Path.new(@pathname.parent + (basename + "_#{suffix}" + extension)) : nil
    end

    # Return whether this Path contains the given Path, Pathname, or String representing a file
    # path.
    #
    # @param [Path, Pathname, String] other The file or folder to be checked.
    # @return [TrueClass, FalseClass] Whether the given file or folder is contained in this Path.
    def contains?(other)
      if other.is_a?(String)
        path = Path.new(Pathname.new(other))

      elsif other.is_a?(Pathname)
        path = Path.new(other)

      elsif other.is_a?(Path)
        path = other

      else
        raise "Pathname#contains got an argument it didn't recognize."
      end

      other.absolute.start_with?(absolute)
    end

    def pwd
      Pathname.pwd
    end

    def to_s
      @pathname.to_s
    end

    # Return the absolute path of this Path object as a String.
    def absolute
      absolute_path.to_s
    end

    def absolute_path
      @pathname.expand_path
    end

    # Return the relative path of this Path object as a String.
    def relative
      tr = relative_path.to_s
      return "" if tr == "."
      tr
    end

    def relative_path
      @pathname.expand_path.relative_path_from(pwd.expand_path)
    end

    def descend(&block)
      @pathname.descend(&block)
    end

    def ascend(&block)
      @pathname.descend(&block)
    end

    def exists?
      @pathname.exist?
    end

    def folder?
      @force_is_folder ? true : @pathname.directory?
    end

    def file?
      @force_is_file ? true : @pathname.file?
    end

    # Return the contained children of this Path as an array of Path objects.
    #
    # @return [Array] An array of Path objects.
    def children
      @children ||= get_children
    end

    def get_children
      # Run these checks first. If the pathname doesn't exist, we can't check for its children. If
      # the folder has no children, it's nil.
      return nil if not exists?
      return nil if @pathname.children.nil?
      if file?
        nil
      else
        # Includes hidden files
        pathname_children = @pathname.children
        pathname_children.reject { |c| c.basename.to_s[0].chr == "." }.collect {|c| Path.new(c)}
      end
    end

    def files
      children.select {|path| path.file?}
    end

    def folders
      children.select {|path| path.folder?}
    end

    def url_for(prefix=nil)
      Url.new(self, prefix=prefix)
    end
  end

end


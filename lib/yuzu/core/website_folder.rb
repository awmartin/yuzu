require 'core/website_file'

module Yuzu::Core
  class WebsiteFolder < WebsiteBase
    def initialize(path, parent)
      raise "Not a Path object." if not path.is_a?(Path)
      @path = path
      raise "@path is nil for #{self}" if @path.nil?
      @parent = parent
      @kind = :folder
    end

    def to_s
      "WebsiteFolder(#{@path})"
    end

    # -------------------------------------------------------------------------------------------
    # TODO Find a way for folders to know what all the categories are, or better yet, remove this
    # interface and have another way of files, folders, and processors to ask information about the
    # entire site.
    #def all_categories
    #end

    def breadcrumb
      Yuzu::Renderers::BreadcrumbRenderer.new.render(self)
    end

    def currentpath
      Yuzu::Filters::CurrentpathFilter.new.value(self)
    end
    # -------------------------------------------------------------------------------------------

    def name
      @path.rootname.titlecase
    end

    def files
      @files ||= children.select {|child| child.file?}
    end

    def folders
      @folders ||= children.select {|child| child.folder?}
    end

    def all_files
      @all_files ||= get_all_files
    end

    def get_all_files
      v = Visitor.new(proc {|c| c.file?})
      tr = []
      v.traverse(self) do |website_file|
        tr.push(website_file)
      end
      tr
    end

    def processable_children
      children.select {|child| child.processable?}
    end

    # Returns all the descendants of this folder, as deep as the tree goes, that are "processable"
    # as specified by the config.
    #
    # @return [Array] Of WebsiteFiles representing content that can be translated into HTML or other
    #   publishable form.
    def all_processable_children
      all_files.select {|child| child.processable? and not child.hidden?}
    end

    # Returns an array of immediate children, files and folders.
    def children
      @children ||= get_children
    end

    # Add a new child object to the @children. Used by generators to add new files to the existing
    # file-system-gathered pages. This method should only be called in a generator, since their
    # execution is managed in such a way that new children are added at the right stage of
    # processing.
    #
    # @param [WebsiteFile, WebsiteFolder] new_child The new generated object to add a child.
    # @return nothing
    def append_child(new_child)
      # Ensure we get the children from disk first.
      children
      @children.push(new_child)
    end

    def get_children
      tr = folder_contents.collect { |child_path| get_object_for_path(child_path) }
      tr.reject {|c| c.nil?}
    end

    # Returns a WebsiteFile or WebsiteFolder for the given path.
    #
    # @param [Path] path The Path object representing the on-disk file or folder.
    # @return [WebsiteFile, WebsiteFolder, nil] The child of this folder.
    def get_object_for_path(path)
      # TODO Add different file types: processable, resource, etc.

      if path.file?
        WebsiteFile.new(path, self)

      elsif path.folder?
        WebsiteFolder.new(path, self)

      else
        # ignore
        nil
      end
    end

    def folder_contents
      @path.children
    end

    # Gets a child by its Path object.
    def get_child_by_path(path)
      children.each do |child|
        return child if child.path == path
      end
      nil
    end

    # Gets a child by a file's filename or a folder's name.
    def get_child_by_rootname(rootname)
      children.each do |child|
        return child if child.path.rootname == rootname
      end
      nil
    end

    # Gets a child by the filename's basename. For index.md, this would be index. Folders return
    # nil.
    def get_child_by_basename(basename)
      children.each do |child|
        return child if child.path.basename == basename
      end
      nil
    end

    # Gets a child by the filename alone. e.g. index.md. Folders return nil.
    def get_child_by_filename(filename)
      children.each do |child|
        return child if child.path.filename == filename
      end
      nil
    end

    def is_immediate_child?(web_obj)
      children.include?(web_obj)
    end

    def is_child?(web_obj)
      folders_only = proc {|c| c.folder?}
      tr = self.is_immediate_child?(web_obj)
      return true if tr

      v = Visitor.new(folders_only)
      v.traverse(self) do |website_folder|
        tr ||= website_folder.is_immediate_child?(web_obj)
      end
      tr
    end

    def has_index?
      @has_index ||= get_has_index
    end

    def get_has_index
      child_names = files.collect do |file|
        filename = file.filename
        ext = File.extname(filename)
        filename.sub(ext, "")
      end
      child_names.include?("index")
    end
  end

end



module Wren::Core

  # Visitor is a convenience mechanism for traversing a tree structure. To be traversable, objects
  # in the data structure must have the following interface defined:
  #
  #     def children
  #       return an array of nodes or nil
  #     end
  #
  # WebsiteBase and Path have this interface, so are traversable. Given a Proc that returns a
  # boolean, we can limit the operation performed by the visitor to a subset of available nodes.
  #
  # Usage:
  #
  #     filter_for_files_only = proc {|c| c.file?}
  #     v = Visitor.new(filter_for_files_only)
  #     v.traverse(root) do |child|
  #       # Do something with child.
  #     end
  #
  # Each node passing the `filter_for_files_only` filter will be executed in the given block.
  class Visitor

    # Create a visitor
    #
    # @param [Proc] filter A proc that returns true/false given the child object in question
    def initialize(filter=nil)
      #raise "Visitor must be given a Proc." if not filter.is_a?(Proc)
      @filter = filter.nil? ? proc {|c| true} : filter
    end

    def traverse(container, &block)
      return if container.children.nil?

      container.children.each do |child|
        block.call(child) if @filter.call(child)
        self.traverse(child, &block) if not child.children.nil?
      end
    end
  end

end


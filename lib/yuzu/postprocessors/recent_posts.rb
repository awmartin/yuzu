require 'postprocessors/base'

module Yuzu::PostProcessors

  class RecentPostsPostProcessor < PostProcessor
    def initialize
      @name = :recent_posts
    end

    def regex
    end

    def value(website_file)
      # Only one set of recent posts per site, so we can cache this.
      @value ||= get_value(website_file)
    end

    def get_value(website_file)
      processable = website_file.blog_folder.all_processable_children
      user_authored = processable.reject {|file| file.generated? or file.index?}
      user_authored.sort {|a, b| b.modified_at <=> a.modified_at}[0...10]
    end
  end
  PostProcessor.register(:recent_posts => RecentPostsPostProcessor)

end


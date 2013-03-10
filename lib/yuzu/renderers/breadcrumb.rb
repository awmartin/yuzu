require 'helpers/import'
import 'helpers/path'
import 'html/base'
import 'yuzu/renderers/base'

module Yuzu::Renderers
  class BreadcrumbRenderer < Renderer
    def render(website_file)
      Breadcrumb.new(website_file).to_s
    end
  end
  Renderer.register(:breadcrumb => BreadcrumbRenderer)

  class Breadcrumb
    def initialize(website_obj, level=0)
      @website_obj = website_obj
      @level = level
    end

    def to_s
      @website_obj.nil? ? "" : crumbs_to_s
    end

    def crumbs_to_s
      ordered_crumbs.collect {|crumb| crumb.to_s}.join(separator)
    end

    def separator
      "&nbsp;#{config.breadcrumb_separator}&nbsp;"
    end

    def reverse?
      true        # TODO make configurable
    end

    def ordered_crumbs
      crumbs
      #reverse? ? crumbs.reverse : crumbs
    end

    def crumbs
      tr = []
      level_correct = 0
      ordered_structure.each_index do |i|
        crumb_tag = ordered_structure[i]
        crumb = crumb_for(crumb_tag, @level + i + level_correct)
        if crumb.nil?
          level_correct -= 1
        end
        tr.push(crumb)
      end
      tr.reject {|el| el.nil?}
    end

    def crumb_for(crumb_tag, level)
      case crumb_tag
      when :home
        Crumb.new(@website_obj.root, level)

      when :blog
        Crumb.new(@website_obj.blog_folder, level)

      when :category
        folder? ? nil : CategoryCrumb.new(@website_obj, level)

      when :post
        if index?
          # Defer to parent.
          nil
        else
          Crumb.new(@website_obj, level)
        end

      when :parent
        @website_obj.parent.nil? ? nil : Breadcrumb.new(@website_obj.parent, level)

      else
        nil

      end
    end

    def ordered_structure
      reverse? ? structure.reverse : structure
    end

    def structure
      if file? and in_blog? and not is_blog? and not index?
        [:home, :blog, :category, :post]

      else
        [:parent, :post]

      end
    end

    def in_blog?
      @website_obj.in_blog?
    end

    def is_blog?
      @website_obj.is_blog?
    end

    def config
      @website_obj.config
    end

    def index?
      @website_obj.index?
    end

    def folder?
      @website_obj.folder?
    end

    def file?
      @website_obj.file?
    end
  end


  class Crumb
    def initialize(website_obj, level=0)
      @website_obj = website_obj
      @level = level
    end

    def to_s
      Html::Link.new(
        :href => @website_obj.link_url,
        :class => "breadcrumb_#{@level}"
      ) << @website_obj.name
    end
  end


  # A crumb for blog categories. For multiple categories, this currently adds links for all of them,
  # separated by a slash.
  class CategoryCrumb < Crumb
    include Helpers

    def initialize(website_file, level=0)
      @website_file = website_file
      @categories = website_file.categories
      @level = level
    end

    def to_s
      Html::Span.new(:class => "breadcrumb_#{@level}") << links.join(separator)
    end

    def links
      @categories.collect {|cat| cat.link}
    end

    def separator
      "&nbsp;/&nbsp;"
    end
  end

end



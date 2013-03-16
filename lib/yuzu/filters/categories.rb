require 'helpers/import'

import 'helpers/url'
import 'helpers/path'

import 'yuzu/filters/base'


module Yuzu::Filters
  # The Categories Filter enables the CATEGORIES() and CATEGORY() directives in posts, that enable
  # an author to produce a set of content categories scoped to the blog or the entire site. These
  # categories are managed and collected so Yuzu can generate HTML links for categories, generate
  # filtered views that contain all posts of a given category, and so on.
  #
  # Categories can be specified for a given post with a comma-separated list:
  #
  #     CATEGORIES(design, process, user experience)
  #
  # These strings ("design", "process", "user experience") become Category objects in Yuzu's 
  # internal representation.
  class CategoriesFilter < Filter
    def initialize
      @name = :categories
      @directive = "CATEGORIES"
    end

    def regex
      Regexp.new('^\s*CATEGOR[\w]*\(([\w\W]*?)\)')
    end

    def default(website_file)
      [Category.new("uncategorized", website_file)]
    end

    def get_value(website_file)
      m = match(website_file.raw_contents)
      return default(website_file) if m.nil?

      category_list = m.split(",")
      category_list.collect! {|cat| cat.strip.downcase}
      category_list.reject! {|cat| cat.empty?}
      category_list.collect {|cat| Category.new(cat, website_file)}
    end
  end
  Filter.register(:categories => CategoriesFilter)


  # Represents a single category given a String. An instance provides the mechanism to represent a
  # link to the category's generated folder, a human-readable version of the category, etc.
  #
  # They are indexed by the lower-case, dashified version of the author-specified string. Thus, 
  # "user experience" and "User Experience" become the same Category, but not "UserExperience".
  class Category
    attr_reader :name

    def initialize(name, website_file)
      @name = name.dasherize.downcase
      @website_file = website_file
    end

    # Returns the render-friendly name of the category, e.g. "User Experience".
    def display_name
      @name.titlecase
    end

    # Returns an HTML link to this category's generated folder. See the CategoryFoldersGenerator.
    def link
      Html::Link.new(:href => url) << display_name
    end

    # Return a Url object holding the link url to this Category's generated folder index. Again, see
    # CategoryFoldersGenerator. If the category was specified in a blog post, the Category Url will
    # refer to the blog subfolder for the category, e.g. blog/user-experience/index.html. If not, it
    # will be a top-level folder. user-experience/index.html
    def url
      if @website_file.in_blog?
        blog_folder.currentpath + @name + "index.html"
      else
        siteroot.currentpath + @name + "index.html"
      end
    end

    # Returns a Path object that represents the folder's location on disk, as a file Path, not a
    # Url (as the url method returns). Like url, this returns the path relative to the blog folder
    # if the Category was specified in a blog post, otherwise, it returns a folder path relative to
    # the root.
    def path
      if @website_file.in_blog?
        blog_folder.path + @name
      else
        siteroot.path + @name
      end
    end

    def blog_folder
      @website_file.blog_folder
    end

    def siteroot
      @website_file.root
    end

    def <=>(other)
      @name <=> other.name
    end
  end
end


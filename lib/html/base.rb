# Html provides a concise way of programmatically expressing HTML tags and structure.
#
# This enables one to express a list like this:
#
#     Html::UnorderedList.new << (Html::ListItem.new << "first") + (Html::ListItem.new << "second")
#
# which results in:
#
#     <ul><li>first</li><li>second</li></ul>
#
# The << operator means "contains", and reduces an Html object and a string to another string. So 
# after the << operation, the tags just obey String semantics.
#
# Commonly used nested tags can be composited and deployed as templates multiple times.
#
#     title_link = Html::H1.new << Html::Link(:href => "http://mysite.com")
#     title_link << "My Site"
#
# which results in:
#
#     <h1><a href="http://mysite.com">My Site</a></h1>
#
# This is seemingly more verbose that writing it directly, but it enables you to write HTML without
# having to do string interpolation and concatenation, and it doesn't imbue Ruby code with a lot of
# HTML-related strings.
#
#     words = %w(hello doctor name continue yesterday tomorrow)
#     Html::UnorderedList.new << words.collect {|w| Html::ListItem.new(:class => "class-#{w}") << w}.join
#
# which will yield:
#
#     <ul>
#       <li class="class-hello">hello</li>
#       <li class="class-doctor">doctor</li>
#       <li class="class-name">name</li>
#       <li class="class-continue">continue</li>
#       <li class="class-yesterday">yesterday</li>
#       <li class="class-tomorrow">tomorrow</li>
#     </ul> 

module Html
  # The base Html class provides functionality for wrapping HTML tags, e.g. <div>...</div>
  class Base
    def initialize(attr={})
      @attr = attr
    end

    @tag = "div"
    def self.tag
      @tag
    end

    def tag
      self.class.tag
    end

    def attributes
      @attr.length == 0 ? "" : @attr.collect {|key, value| " #{key.to_s}='#{value}'"}.join
    end

    def processed_output(contents)
      "<#{tag}#{attributes}>#{contents}</#{tag}>"
    end

    def << (other)
      if other.is_a?(String)
        processed_output(other)
      else
        Composite.new(self, other)
      end
    end
  end

  # Class that sets off the tag by newlines to aid in readability for raw output.
  class Container < Base
    def processed_output(contents)
      "\n<#{tag}#{attributes}>\n#{contents}\n</#{tag}>\n"
    end
  end

  class Item < Base
    def processed_output(contents)
      "<#{tag}#{attributes}>#{contents}</#{tag}>\n"
    end
  end

  # Class for compositing nested tags togther and using them multiple times in different contexts.
  class Composite
    def initialize(first, second)
      @first = first
      @second = second
    end

    def << (other)
      if other.is_a?(String)
        @first << (@second << other)
      else
        Composite.new(self, other)
      end
    end
  end

  # HTML flags are those that don't have a closing tag, e.g. <img href="">
  class Flag < Base
    def to_s
      "<#{tag}#{attributes}>"
    end

    def << (other)
      self.to_s + other
    end
  end

  # Handler for adding HTML <!-- comments --> inline.
  class Comment < Base
    def << (other)
      "\n<!-- #{other} -->\n"
    end
  end

  # Class handler for <div> tags.
  class Div < Container
    instance_variable_set(:@tag, "div")
  end

  # Class handler for <a> links.
  class Link < Base
    instance_variable_set(:@tag, "a")
  end

  # Class handler for <li> list item tags.
  class ListItem < Item
    instance_variable_set(:@tag, "li")
  end

  # Class handler for <ul> unordered lists.
  class UnorderedList < Container
    instance_variable_set(:@tag, "ul")
  end

  # Handler for <ol> ordered lists.
  class OrderedList < Container
    instance_variable_set(:@tag, "ol")
  end

  # Handler for <h1> headers.
  class H1 < Item
    instance_variable_set(:@tag, "h1")
  end

  # Handler for <h2> headers.
  class H2 < Item
    instance_variable_set(:@tag, "h2")
  end

  # Handler for <h3> headers.
  class H3 < Item
    instance_variable_set(:@tag, "h3")
  end

  # Handler for <h4> headers.
  class H4 < Item
    instance_variable_set(:@tag, "h4")
  end

  # Handler for <span> tags.
  class Span < Base
    instance_variable_set(:@tag, "span")
  end

  # Handler for <p> paragraph tags.
  class Paragraph < Container
    instance_variable_set(:@tag, "p")
  end

  # Handler for <img> images.
  class Image < Flag
    instance_variable_set(:@tag, "img")
  end

  # Handler for <br> line breaks.
  class Break < Flag
    instance_variable_set(:@tag, "br")
  end

end


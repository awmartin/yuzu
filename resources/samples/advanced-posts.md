# A More Advanced Post

Posts can take advantage of a number of _directives_ to mix content and tag the post with additional information. This one shows you by example how to use the most common ones.

Notice how the post is dated February 11, 2013. This is set by using the `DATE` directive at the bottom of the post, after the `SIDEBAR`. Directives like this are removed from the raw contents of the post, processed, and placed according to the HAML _templates_ located in the folder called `_templates`.

SIDEBAR{
This is text that will appear in the sidebar.

You can make this by using the `SIDEBAR` tag, which uses curly braces to offset text to be placed with `post.sidebar` in a HAML template.
}
DATE(2013-02-11)

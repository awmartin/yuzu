# A More Advanced Post

Posts can take advantage of a number of _directives_ to mix content and tag the post with additional information. This one shows you by example how to use the most common ones.

Notice how the post is dated February 11, 2013. This is set by using the `DATE` directive at the bottom of the post, after the `SIDEBAR`. Directives like this are removed from the raw contents of the post, processed, and placed according to the HAML _templates_ located in the folder called `_templates`.

Here we will insert some contents from a different file:

    INSERTCONTENTS(_snippets/about_insert_contents.md)

If you look at the source, the directive is indented. I only do this because Markdown highlighters treat underscores as markup to italicize text. Indenting treats it as code with no markup applied.

SIDEBAR{
This is text that will appear in the sidebar.

You can make this by using the `SIDEBAR` tag, which uses curly braces to offset text to be placed with `post.sidebar` in a HAML template.
}
DATE(2013-02-11)

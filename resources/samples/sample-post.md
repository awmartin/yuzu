# Sample Yuzu Post

This what a typical post looks like in Yuzu.

It is written in [Markdown](http://daringfireball.net/projects/markdown/) and may contain various tags called "directives" (in ALLCAPS in other posts), that either indicate to Yuzu pieces of information about this post (e.g. the desired publication date of this page) or instructions on what to render (like inserting the contents of another file).

## Writing Posts

You don't have to include any directives in a post; you can simply write Markdown as usual (or other formats, coming soon), like any other text file. By default, Yuzu grabs all the "processable" files (ones indicated in the configuration by their extension), and turns them into HTML files by passing them through a series of transformations.

One of the things to notice here is that the title of the post is extracted from the first hash `#` header tag at the top. If this weren't here, the title would be extracted from the file name. In this case, it would be "Sample Post," a titleized form of the tile name.

For an example of what a post with directives looks like, see [A More Advanced Post](advanced-posts.html).

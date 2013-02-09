# Wren Tag Reference

## Post Titles

Specify the title of a post, available with `post.post_title`, with the following placed in your file:

    TITLE(Post Title)

If the `TITLE(...)` tag is not present, wren will attempt to use rules from the translators. For Markdown, it grabs "# ...". If not present, wren will extrapolate the title from the filename. Files should be named in one of two ways:

    a-post-title.md
    2011-10-10-a-post-title.md

## Catalogs

A catalog is a listing of posts and pages rendered in a partial form. An example would be an index page of blog posts. This allows you to insert several sets of posts from different parts of a website.

    INSERTCATALOG(path:folder-name)
    INSERTCATALOG(path:folder-name, per_page:10, per_col:1, template:_block.haml)

* `path`  
The folder containing the posts to be placed into the catalog.
* `total`
The number of posts to be shown in this catalog.
* `per_col`  
Catalogs are grids of posts rendered with the _template_ specified. This field specifies how many columns there are in the grid. Use 1 (default) for a straight run of typical blog posts.
* `template`  
The name of the template file in the `_templates` folder to apply to each item in the catalog (e.g. _block.haml)
* `category`  
A category filter, showing pages that only have this category.
* `page`  
To control which page to render, such as only the first page, use this field. If not present, wren will attempt to paginate the _first_ catalog found in a page without this flag.

## Images

Adding an images tag provides a mechanism for galleries and other renderers to reference those images in a structured way.

    IMAGES(
        LINKROOT/img/image01.png,
        LINKROOT/img/image02.png
    )

## Categories

Categories for blog posts (files only showing up in the `blog_dir` folder) can be specified by setting them explicitly in the content of a post:

    CATEGORIES(Architecture, Design)

The list of categories is available in the `post.categories` variable in all HAML templates. For all the categories in a site, use `post.all_categories`.

## Sidebar Content

Contents of sidebars can be separated by using the tag below. This supports the ability to lay out the sidebar in the templates, instead of putting layout and HTML structure the posts themselves.

    SIDEBAR{
      This will show up in the "post.sidebar" variable inside templates.
    }

The format of all contents between the braces must match the contents of the file itself (e.g. Markdown).

## Templates

All HAML files in the template_dir folder, specified in wren.yml, are considered templates, where several default variables are available to access and insert content.

Specifying which template to use for a particular file can be achieved with the TEMPLATE tag:

    TEMPLATE(_default.haml)

wren automatically looks in the `_templates` folder for the HAML files to use. The default templates required by wren are:

* `index.haml`  
    The template for index.html pages.
* `generic.haml`  
    The overall template for all other generic pages and posts (default).

## Templates and Partials

"Partials" are templates that are rendered as part of other templates. They typically contain repeated contents and information that are context-dependent, but cannot be rendered on their own. 

The default templates and partials that must be specified are as follows:

* `_header.haml`  
    A partial that contains any header content for a typical page.
* `_footer.haml`  
    Partial that contains any footer for a typical page.
* `_menu.haml`  
    Partial with the global navigation menu.
* `_head.haml`  
    Partial containing the HTML `<head></head>` tag for all typical pages.
* `_gallery.haml`  
    Partial that renders a gallery of images. Optional.

These are automatically generated with the `create` command when creating a new wren project from scratch. Partials and auto-generated templates have a leading underscore as part of their name. Your custom templates don't have to have this.





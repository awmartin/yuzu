# WREN Tag Reference

## Post Titles

TITLE(Post Title)

If the TITLE() tag is not present, wren will extrapolate the title from the filename. Files should be named in one of two ways:

`a-post-title.md
2011-10-10-a-post-title.md`

## Catalogs

A catalog is a listing of posts and pages rendered in a partial form. An example would be an index page of blog posts. This allows you to insert several sets of posts from different parts of a website. The 

`INSERTCATALOG(folder/path, first_post, number of posts, posts per column, template, category)`

`INSERTCATALOG(folder/path, PAGINATE, number of posts per page, posts per column, template, category)`

* first post  
    Index of the firts post to show. Indexed at 0. If this field is set to PAGINATE, multiple pages will be generated.
* number of posts  
    Simply the number of posts to be shown in this catalog
* posts per column  
    Catalogs are grids of posts rendered with the _template_ specified in the next field. This field specifies how many columns there are in the grid. Use 1 for a straight run of typical blog posts.
* template  
    The name of the template file in the _templates folder to apply to each item in the catalog (e.g. _block.haml)
* category
    A category filter, showing pages that only have this category.

## Images

Adding an images tag provides a mechanism for galleries and other renderers to reference those images in a structured way.

`IMAGES(
    LINKROOT/path/to/image01.png,
    LINKROOT/path/to/image01.jpg
)`

## Categories

Categories for blog posts (files only showing up in the blog_dir folder) can be specified one of two ways. Setting them explicitly in the content of a post involves the CATEGORY tag:

`CATEGORIES(Architecture, Design)`

Otherwise, the first set of subfolders in blog_dir will set the category name for all of the files therein.

The list of categories is available in the `categories` variable in all HAML templates.

## Sidebar Content

Contents of sidebars can be separated by using the tag below. This supports the ability to lay out the sidebar in the templates, instead of putting layout and HTML structure the posts themselves.

`SIDEBAR{
    This will show up in the sidebar.
}`

The format of all contents between the braces must match the contents of the file itself.

# Templates

All HAML files in the template_dir folder, specified in wren.yml, are considered templates, where several default variables are available to access and insert content.

Specifying which template to use for a particular file can be achieved with the TEMPLATE tag:

`TEMPLATE(_default.haml)`

where the template is the full filename of the template file, without template_dir.

# Specifying templates and partials.

"Partials" are templates that are included as part of other templates. They typically contain repeated contents and information that are context-dependent, but cannot be rendered on their own. 

The default templates and partials that must be specified are as follows:

* _header.haml  
    A partial that contains any header content for a typical page.
* _footer.haml  
    Partial that contains any footer for a typical page.
* _menu.haml  
    Partial with the global navigation menu.
* _head.haml  
    Partial containing the HTML `<head></head>` tag for all typical pages.
* _gallery.haml  
    Partial that renders a gallery of images. Optional.
* _index.haml  
    The overall template for index pages.
* _generic.haml  
    The overall template for all other generic pages.

These are automatically generated with the `create` command. Partials and auto-generated templates have a leading underscore as part of their name. Your custom templates don't have to have this.





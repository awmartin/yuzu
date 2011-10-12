

## INSERTCATALOG

`INSERTCATALOG(folder/path, first post, number of posts, posts per column, template, category)`  
`INSERTCATALOG(folder/path, PAGINATE, number of posts per page, posts per column, template, category)`

* first post  
    Index of the firts post to show. Indexed at 0. If this field is set to PAGINATE, multiple pages will be generated.
* number of posts  
    Simply the number of posts to be shown in this catalog
* posts per column  
    Catalogs are grids of posts rendered with the _template_ specified in the next field. This field specifies how many columns there are in the grid. Use 1 for a straight run of typical blog posts.
* template  
    The name of the template file in the _templates folder to apply to each item in the catalog (e.g. _block.haml)


## IMAGES


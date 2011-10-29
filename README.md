Wren (the "Website RENderer") is a blog-aware static website generator and publisher that converts a folder structure with text files and images into an HTML5 website and other formats. It can publish the rendered HTML output to an FTP server, local or remote file system, or Amazon S3.

Wren is unique among other static generators in that:  

1. any file or folder contents can be mixed and inserted into other files,  
2. content can be published in various forms (regular HTML, jQuery slideshow, PDF, etc.). 

Wren supports many features of CMS systems but without having to install resource-intensive publishing software like Wordpress, Drupal, Mephisto, Typo, or Expression Engine, but wren is best for small sites that need fast deployment.


## Key Features

A major design goal was to make the setup and metadata overhead as low as possible for users. Other website generators require you to specify metadata for every page, such a YAML header. Wren chooses "wise defaults" and derives some properties without having to explicitly specify them. For example, page and post titles are extracted from the file name, unless explicitly declared in the source with a TITLE tag. This enables you to make a complete website without typing any metadata at all if you need to work quickly. Just type the content and publish.

Wren distinguishes between local preview and remote publication. Previews allow you to use a local Apache instance (like Web Sharing on a Mac) or Dropbox Public folder to view the polished, rendered website before publishing it on the web.

For local previews, instead of stashing the rendered website into a "site" folder inside the project, you can specify any folder on your harddrive. For example, on a Mac, you can specify your Sites folder (~/Sites/my-site) and view it with Web Sharing in Safari (http://localhost/~username/my-site).

For remote publication, Wren provides interfaces for Amazon Simple Storage Service (S3), FTP for regular web servers, and SSH/SFTP for secure remote file servers. Specifying a local shared folder, like Dropbox's Public folder, can also be a way to publish a website.

Also, with content mixing, a user can structure raw content irrespective of the website structure. If you're writing about a topic organized in a deep, hierarchical content tree, you can remix and publish the same content in the website structure without having to copy files or copy/paste text. Just use INSERTCONTENTS to insert the contents of another file into this one. In this way, you can author with one folder structure and publish with another, or support two means of browsing and navigating the same content.

With the proper gems installed, Wren will also build PDF and slideshow versions of webpages. It has a set of rules that translate headers and other structural tags into slides, for example, or into multi-page PDF files. If you structure your pages a particular way, you can create presentations with a printed and web version in one go.


## Sample Workflow

1. Edit files
2. Open Terminal.app
3. cd ~/Sites/my-site
4. wren publish:all
5. View in Safari, http://localhost/~username/my-site


## Features List

* HTML5 website generation from a folder of text files
* Content mixing, meaning:  
  * insert the raw contents of one file into another
  * generate a list with contents of all the files of a particular folder, formatted with HAML templates  
    (An example of this would be a blog landing page, where you see 10 posts listed in chronological order, but only the title and first paragraph are shown for each. Pages like this can be generated with simple text directive pointing to a folder and a template file.)
* Pages generate with zero configuration.
* Multiple output file support (accordion pages, Javascript-powered slideshows, PDF files)
* Multiple format support (plaintext, textile, markdown, HAML)
* Uses Compass for SASS (or SCSS) to CSS
* Page templates and partials
* A blog folder for more blog-like content
* Automatic index.html file generation for folders.  
  If you have a folder structure of text files already, you can copy in all of them without having to generate any new files. Wren generates index.html files for every folder, inserting a "catalog" of the files in that folder. You can customize this of course, but this is designed to enable the easiest route from a set of text files to a website.
* Pagination of index files
* Dependency updates for inserted content
* Watcher for efficient workflow
* Local preview publication (e.g. Sites folder on a Mac, running Apache with "Web Sharing" enabled)
* On Mac: thumbnail generation


## Contributing to wren
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.


## Copyright

Copyright (c) 2011 William Martin. See LICENSE.txt for further details.


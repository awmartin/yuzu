Yuzu is a blog-aware, static-website generator and publisher that builds an HTML5 website from a
folder of text files and images.

For an example of a site rendered with Yuzu, see [Spatial Pixel](http://spatialpixel.com).


## Quick Start (Mac)

1. `mkdir ~/Documents/yuzu-project`
2. `cd ~/Documents/yuzu-project`
3. `yuzu create`
4. `yuzu preview`
5. Go go file:///Users/username/Sites/yuzu-project/index.html

For Linux, change `/Users` to `/home`


## Current Features

* Website generation from a folder of text files (Markdown, plain text, HAML, and more) with minimal
  additional configuration.
* Embedded support for multiple publication destinations: FTP, S3, local filesystem (can be used for
  Dropbox's public folder or a local webserver installation).
* Content mixing: Any file can be inserted and rendered into other files (barring circular
  references).
* Templating: Use HAML to make resuable templates, partials, and layout.
* Catalogs: A list of files can be gathered, rendered, and paginated on any page.
* Widget-like components like photo galleries and breadcrumbs.
* Uses Compass and Less for SASS (or SCSS) to CSS.
* A blog folder for periodical content, supporting categories, recent posts, RSS feeds.
* Automatic index.html file generation for folders containing a rendered catalog of the folder's
  contents.
* On Mac: image thumbnail generation.


## Features Coming Soon

* Extensibility: The current implementation supports registering new functionality relatively
  easily. Soon to be refined.
* Multiple publication formats (HTML, jQuery slideshow, PDF, etc.)
* Integration with website tools like Bootstrap and HTML5 Boilerplate
* git hooks for version control and publication management
* Site themes for quick website creation
* Watcher script for efficient workflow.

Yuzu supports many features of CMS systems but without having to install resource-intensive
publishing software like Wordpress, Drupal, Mephisto, Typo, or Expression Engine, but yuzu is best
for small sites that need fast deployment.

Yuzu first came about from the need to publish lecture material for online course material in
multiple formats, specifically a single webpage, javascript-enabled slideshow, and PDF. The
content-mixing functionality was critical. It is intended to support these multiple rendering points
easily so the content only has to be written once. Then the need expanded into building small
project-specific websites quickly.


## Sample Workflow (Mac)

1. Edit your Markdown content files in your favorite text editor
2. Open a terminal
3. `cd ~/Documents/yuzu-project`
4. `yuzu preview`
5. View in a web browser (with Web Sharing enabled): `http://localhost/~username/project-folder`
6. Publish to the web: `yuzu publish`


## Contributing to yuzu
 
* Check out the latest master branch to make sure the feature hasn't been implemented or the bug
  hasn't been fixed yet.
* Fork the repo.
* Run the tests to make sure all is well.
* Create a new branch.
* Commit and push.
* Make sure to add tests for your change.
* Send me a pull request.


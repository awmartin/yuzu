Yuzu is a blog-aware, static-website generator and publisher that builds an HTML5 website from a folder of text files and images.


## Current Features

* Website generation from a folder of text files (Markdown, plain text, HAML, and more) with minimal additional configuration.
* Embedded support for multiple publication destinations: FTP, S3, local filesystem (can be used for Dropbox's public folder or a local webserver installation).
* Content mixing: Any file can be inserted and rendered into other files (barring circular references).
* Templating: Use HAML to make resuable templates, partials, and layout.
* Catalogs: A list of files can be gathered, rendered, and paginated on any page.
* Widget-like components like photo galleries and breadcrumbs.
* Uses Compass and Less for SASS (or SCSS) to CSS.
* A blog folder for more blog-like content, supporting categories, recent posts, RSS feeds.
* Automatic index.html file generation for folders.
* Watcher script for efficient workflow.
* On Mac: image thumbnail generation.


## Features Coming Soon

* Extensibility: The current implementation supports registering new functionality relatively easily. Soon to be refined.
* Multiple publication formats (HTML, jQuery slideshow, PDF, etc.)
* Integration with website tools like Bootstrap and HTML5 Boilerplate
* git hooks for version control and publication management
* Site themes for quick website creation

Yuzu supports many features of CMS systems but without having to install resource-intensive publishing software like Wordpress, Drupal, Mephisto, Typo, or Expression Engine, but yuzu is best for small sites that need fast deployment.

Yuzu first came about from the need to publish lecture material for online course material in multiple formats, specifically a single webpage, javascript-enabled slideshow, and PDF. The content-mixing functionality was critical. It is intended to support these multiple rendering points easily so the content only has to be written once. Then the need expanded into building small project-specific websites quickly.


## Sample Workflow (Mac)

1. Edit your Markdown content files
2. Open a terminal
3. `cd ~/Documents/yuzu-projects/project-folder`
4. `yuzu preview:all`
5. View in a web browser: `http://localhost/~username/project-folder`
6. Publish to the web: `yuzu publish:all`


## Contributing to yuzu
 
* Check out the latest master branch to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Fork the repo.
* Run the tests to make sure all is well.
* Create a new branch.
* Commit and push.
* Make sure to add tests for your change.
* Send me a pull request.


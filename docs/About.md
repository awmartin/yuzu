# About

The primary design objective for Yuzu was to build a publication tool that supports:

1. multiple media endpoints (website, javascript slideshow, PDF),
2. content mixing, to support separate organizations for content in its raw form versus its published form (depending on the endpoint medium), and
3. embedded publication capabilities (FTP, S3, filesystem).

A major design goal was to require users to get started with as little setup and metadata overhead as possible. Other website generators require you to specify metadata for every page, such a YAML header. Yuzu derives some properties without having to explicitly specify them. For example, page and post titles are extracted from the file name, unless explicitly declared with a tag. This enables you to make a complete website without typing any metadata at all if you need to work quickly. Just author the content and publish.

For example, if you have a folder structure of text files before using Yuzu, you can generate a website from them without creating any new files yourself. Yuzu generates index.html files for every folder and inserts a "catalog" of those files' contents. You can customize this of course, but this is designed to enable the easiest route from a set of text files to a website.

Yuzu distinguishes between local preview and remote publication. Previews allow you to use a local Apache instance (like Web Sharing on a Mac) or Dropbox Public folder to view the polished, rendered website before publishing it on the web.

For local previews, instead of stashing the rendered website into a "site" folder inside the project, you can specify any folder on your harddrive. For example, on a Mac, you can specify your Sites folder (~/Sites/my-site) and on a Mac, view it with Web Sharing (http://localhost/~username/my-site) or another Apache instance.

For remote publication, Yuzu provides interfaces for Amazon Simple Storage Service (S3) and FTP for regular web servers. Specifying a local shared folder, like Dropbox's Public folder, can also be a way to publish the site.

Also, with content mixing, a user can structure raw content irrespective of the website structure. If you're writing about a topic organized in a deep, hierarchical content tree, you can remix and publish the same content in the website structure without having to copy files or copy/paste text. Just use INSERTCONTENTS to insert the contents of another file into this one. In this way, you can author with one folder structure and publish with another, or support two means of browsing and navigating the same content.

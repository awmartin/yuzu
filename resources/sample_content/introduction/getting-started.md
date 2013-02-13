# Getting Started with Yuzu

If you're reading this, you've successfully created your yuzu project, and you're likely browsing the source of the new project.


## Home

The front page is `index.md`, found in the folder you ran `yuzu create` in. If you look in it, you'll see a directive called `INSERTCATALOG`. Directives such as these are the mechanism that enables you to give Yuzu various instructions or information to aid in rendering your site.


## Creating Your First Yuzu Project

The fastest way to get started is to generate the sample project. Create a folder first and `cd` into it.

1. `mkdir ~/Documents/yuzu-sample`
2. `cd ~/Documents/yuzu-sample`
3. `yuzu create`
4. `yuzu preview`
    
Then point your browser to `file:///your/home/folder/Sites/yuzu-sample/index.html`.


## Configuration

You should edit `config/yuzu.yml` to update the path found under `preview` called `destination`. If you're on a Mac, simply run change `username` to your username.

If you have an local Apache server running, or a Mac with Web Sharing enabled, you can reset the `services: preview: link_root:` flag in `yuzu.yml` to the project folder's url. e.g. `http://localhost/~yourusername/yuzu-sample`

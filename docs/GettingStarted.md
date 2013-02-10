# Getting Started with Yuzu

Using yuzu requires some familiarity with using a terminal application. On a Mac, this is Terminal.app or iTerm2.app.


## Creating a New Project

1. Create a folder for your project.
2. Open your terminal.
3. Change the directory into your project folder, e.g.

    cd ~/Documents/Projects/my-yuzu-project

4. Create the yuzu project. This command will copy a series of files into the directory, including setting up a Compass project for SASS/SCSS.

    yuzu create


## Edit yuzu.yml

This is a YAML file that contains all the necessary configuration to make Yuzu run properly, such as the public name of the site, configuration settings for the preview, remote FTP server, and so on. 

Read through the comments in this file to get a more complete sense of what the options mean. For now, to get started, all we need is to set the site's name and to put in the preview settings.

    site_name: My First Yuzu Project
    
    connections:
      preview:
        domain: localhost/~username/my-yuzu-project
        destination: /Users/username/Sites/my-yuzu-project
        link_root: /~username/my-yuzu-project

The trickiest setting is `link_root`. This is prepended to every URL to get the relative links right. This is a convenience setting, so you can enter LINKROOT/images/grid.png to get /~username/my-yuzu-project/images/grid.png.

This is useful because our site doesn't live at the root server folder, and yuzu uses relative links by default. You can make all links absolute by changing `link_root` to a fully qualified domain name. You can also forget this entirely and specify the complete URLs yourself.


## Preview the Sample Site

In Terminal, type `yuzu preview:all`

This will generate your website and produce the rendered version in the folder you specified under `destination` above. Yuzu will automatically create this folder for you.

In a web browser, go to http://localhost/~username/my-yuzu-project.





# Getting Started with Wren

Using wren requires some familiarity with using a terminal application. On a Mac, this is Terminal.app.

A future version of wren will provide a GUI that keeps track of projects, previewing, publishing, etc.


## Downloading Wren

Wren is currently published as a Ruby gem.

Open Terminal.app.
Type `sudo gem install wren`. This should automatically start the download.


## Creating a New Project

Create a folder for your project.
Open Terminal.app.
Change the directory into your project folder, for example:

    cd ~/Documents/Projects/my-wren-project

Where `~` stands for your user folder, usually a shortcut for `/Users/username`.

Create the wren project. This command will copy a series of files into the directory, including setting up a Compass project for SASS/SCSS.

    wren create


## Edit wren.yml

This is a YAML file that contains all the necessary configuration to make Wren run properly, such as the public name of the site, configuration settings for the preview, remote FTP server, and so on. Read through the comments in this file to get a more complete sense of what the options mean. For now, to get started, all we need is to set the site's name and to put in the preview settings.

    site_name: My First Wren Project
    
    preview:
        domain: localhost/~username/my-wren-project
        destination: /Users/username/Sites/my-wren-project
        link_root: /~username/my-wren-project

The trickiest setting is `link_root`. This is prepended to every URL to get the relative links right. This is a convenience setting, so you can enter LINKROOT/images/grid.png to get /~username/my-wren-project/images/grid.png.

This is useful because our site doesn't live at the root server folder, and wren uses relative links by default. You can make all links absolute by changing `link_root` to a fully qualified domain name. You can also forget this entirely and specify the complete URLs yourself.


## Preview the Sample Site

In Terminal, type `wren preview:all`

This will generate your website and produce the rendered version in the folder you specified under `destination` above. Wren will automatically create this folder for you.

In a web browser, go to http://localhost/~username/my-wren-project.




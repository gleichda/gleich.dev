---
title: "How Have I Built This Site"
date: 2019-09-21T11:29:45+02:00
draft: true
---

This side is served using [Google Cloud Run](https://cloud.google.com/run/) and created with [Hugo](https://gohugo.io/).
All the development was done via [Google Cloud Shell](https://cloud.google.com/shell/) with my [custom Google Cloud Shell Image](https://github.com/gleichda/cloud-shell).
This custom image contains [code-server](https://github.com/cdr/code-server) and now also [Hugo](https://github.com/gohugoio/hugo)

## Install Hugo

Hugo has some good [documentation](https://gohugo.io/getting-started/installing/) how to install it. 
So I won't tell you that by myself.
Have a look into my personal Google Cloud Shell image if you want to get some inspiration how to get Hugo into a Docker container.

Afterwards verify the installation with:
```
hugo version
```

## Create some git repo

Create some [new GitHub repo](https://github.com/new). 
And connect your local one with the remote.

```bash
mkdir <MYSITE>
cd <MYSITE>
git init
git remote add origin <YOUR NEW REPO>
```

## Launch Code-Server in Cloud Shell

You don't need the authorization as Google handles that for you.

```bash
code-server --no-auth --port 8080 --disable-telemetry .
```

Open the Preview on port 8080. If you get an `Not Found` error just remove the `?authuser=0` from the URL and you have your code-server running in cloud shell.

![Open Web Preview](/img/cloud-shell-preview.png)

## Create your site with Hugo

Open another Cloud Shell instance and navigate your git repository.
Then create the site with hugo.

```
hugo new site <YOUR SITE>
```

Now you see the <YOUR SITE> folder in your directory.
Go into that folder.

```bash
cd <YOUR SITE>
```

### Choose and configure your theme

Look for a [theme](https://themes.gohugo.io/) you like and follow the instructions how to configure it.
I chose the [m10c theme](https://github.com/vaga/hugo-theme-m10c).

Add the theme to your theme path:

```
git submodule add https://github.com/vaga/hugo-theme-m10c.git themes/m10c
```

Add the theme specific config tou your `config.toml` via code server:

```
baseURL = "http://example.org/"
languageCode = "en-us"
title = "My Site"

theme = "m10c"
[params]
  author = "YOU"
    [[params.social]]
        name = "github"
        url = "https://github.com/<YOUR GITHUB USERNAME>"
```

### Watch your site's preview via Cloud Shell

Start the Hugo server on a port above 2000 (I use 2345):

```
hugo serve --port 2345 -D
```

The `-D` also serves the draft content.
Change the Port on the web preview to 2345 and open the preview.

![Change Port and Open Web Preview](/img/cloud-shell-preview.png)

It's the same here. If you get an error remove the `?authuser=0` from the URL and it should work.

### Add your Content

Open another Cloud Shell instance and navigate to the folder where your site is in.
And then create some content:

```bash
hugo new posts/my-first-post.md
```

Reload the preview from Hugo and you should see the new post.
Now you can edit the file in `content/posts/my-first-post.md` and everytime you save Hugo will detect
and when you reload the page it will serve the latest content.

## Commit your changes to GitHub

```bash
# Go into the root of your git repo
cd .. 
# Add your theme and config
git add .gitmodules
git commit -m 'Add submodule theme'
# Add your site
git add <MYSITE>/*
git commit -m 'My first working site'
```

## Create a Cloud Build

In your

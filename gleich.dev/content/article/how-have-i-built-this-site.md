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

## Setup the build

I have my build stuff in a separate directory called `build` except for the Cloud Build as the GitHub App for Cloud Build expects it in the root folder.
So my repo looks like:
```
.
├── build
│   ├── Dockerfile
│   └── run.sh
├── cloudbuild.yaml
├── <MYSITE>
│   ├── archetypes
│   ├── config.toml
│   ├── content
│   ├── data
│   ├── layouts
│   ├── resources
│   ├── static
│   └── themes
└── README.md
```

### Create a small run.sh

Currently Cloud Run is always using Port 8080. But it also can inject another port as the
As Cloud Run can inject the port as env variable `PORT` we need to create a small script that starts hugo on the port that gets injected:

```bash
#! /bin/sh

/usr/bin/hugo serve --port ${PORT}
```

Make the script executable:

```
chmod +x bin/run.sh
```

### Create some Dockerfile

In the build directory create a `Dockerfile`

```Dockerfile
FROM gcr.io/cloud-builders/git as downloader
ARG HUGO_VERSION="0.58.3"

ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /
RUN  tar -xvzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /

FROM alpine:latest
ENV PORT 8080
COPY --from downloader /hugo /usr/bin/hugo
COPY <MYSITE> /<MYSITE>
COPY build/run.sh /run.sh
```

To minimize the size and the number of layers of the Docker image I'm using a separate image for downloading and extracting.

For an easy local running I'm adding the environment variable `PORT` with a suitable value.
If this changes it will be overwritten on the container startup by Google Cloud Run.

### Create a Cloud Build

In the root of your git directory create a `cloudbuild.yaml`.

```yaml
steps:
  - id: Add submodules
    name: gcr.io/cloud-builders/git
    entrypoint: bash
    args:
      - -c
      - |
        git submodule init && \
        git submodule update
  - id: Build dockerfile
    name: gcr.io/cloud-builders/docker
    args:
      - build
      - --tag=gcr.io/${PROJECT_ID}/<MYSITE>:${BRANCH_NAME}
      - --file=build/Dockerfile
      - .
images:
  - gcr.io/${PROJECT_ID}/<MYSITE>:${BRANCH_NAME}
```

In the first step it is downloading the theme we have added as a submodule.
In the second step it is building the image.

With the `images:` Cloud Build knows what artifacts are created and pushes the Image to the Container Registry.
Beaver
======

Beaver is a collection of scripts and utilities to keep
[Travis](https://travis-ci.org) builds in a DRY fashion.

Features
--------

* **Docker:** Beaver allows you to run your build/tests in
  [Docker](https://docker.com/) containers easily, but building a repo-provided
  image and running stuff inside it.

* **Bintray:** Beaver provides scripts to easily upload Debian packages to
  [Bintray](https://bintray.com/) repositories (Travis support is a bit clumsy).


Usage
-----

* Add it as a submodule:

  ```sh
  git submodule add -n beaver \
      https://github.com/sociomantic-tsunami/beaver.git submodules/beaver
  ```

* Add a shortcut to Beaver's bin path to `.travis.yml`:

  ```yml
  env:
      global:
          - PATH="$(git config -f .gitmodules submodule.beaver.path)/bin:$PATH"
  ```


Docker
------

To use Docker in you builds, Beaver expects a `Dockerfile`, even if it's just to
specify which Docker image to use. Then you need to build the Docker image
(normally in the `install:` section of your `.travis.yml` file).

The simplest use case would be:

* `Dockerfile`

  ```dockerfile
  FROM someimage:sometag
  ```

* `.travis.yml`

  ```yml
  install: beaver docker build .
  ```

`beaver docker build` is just a thin wrapper over `docker build` to add some
default options (`--pull -t beaver` in particular).

You can pass extra `docker build` options to `beaver docker build`, for example
to use a different `Dockerfile`:

```yml
install: beaver docker build -f docker/Dockerfile .
```

You can also use this to do matrix builds with different `Dockerfile`s, for
example:

* `docker/Dockerfile.trusty`

  ```dockerfile
  FROM ubuntu:trusty
  ```

* `docker/Dockerfile.xenial`

  ```dockerfile
  FROM ubuntu:xenial
  ```

* `.travis.yml`

  ```yml
  env:
      matrix:
          - DIST=trusty
          - DIST=xenial

  install: beaver docker build -t "docker/Dockerfile.$DIST" .
  ```

Then use `beaver docker run` to run commands inside the docker container (which,
as you might think, is just a thin wrapper over `docker run` passing some
options and the image to use, as well as all Travis environment variables,
mapping the working directory, etc.). For example:

```yml
script:
    - beaver docker run make all
    - beaver docker run make test
```

If you need to pass extra variables to `docker run` you can do it by using the
`BEAVER_DOCKER_VARS` environment variable. To make it globally, you can do, for
example:

```yml
env:
    global:
        - BEAVER_DOCKER_VARS="CC DIST"
    matrix:
        - DIST=trusty CC=gcc
        - DIST=xenial CC=gcc
        - DIST=xenial CC=clang

install: beaver docker build -f "docker/Dockerfile.$DIST" .
```

You can also pass extra options to `docker` by exporting the
`BEAVER_DOCKER_OPTS`.

The docker image name is `beaver`.


beaver install
--------------

This command is an easy entry point for projects that want to use some
conventions.

This script just builds the image for now, but if the `$DIST` environment
variable is defined, then it looks for the `Dockerfile.$DIST` file instead of
the regular `Dockerfile`.

beaver run
----------

This is just a convenience shortcut for `beaver docker run`.

beaver make
-----------

This is a convenience shortcut for `beaver run make -rj2` (for now, in the
future other convenient set of options might be used).


Bintray
-------

To upload Debian packages to Bintray use the `beaver bintray upload` command. By
default you only need to pass the path to the files to upload. The credentials
will be obtained from `$BINTRAY_USER` and `$BINTRAY_KEY` environment variables
and the destination to `org/repo/repo` where `org` is the GitHub
organization/user and `repo` is the GitHub repo name (this is obtained from
`$TRAVIS_REPO_SLUG`). By default the current tag being buit is used as the version
(from `$TRAVIS_TAG`).

Files are put in the debian repository `$DIST/(pre)release/ARCH` where `$DIST`
can also be overriden via command-line arguments and if not present at all
defaults to `$(lsb_release -cs)`, releases are put in the `release` components
and pre-releases (tags with a `-` as per [SemVer]() specification) in the
`prerelease` component. Finally `ARCH` is the architecture and is calculated
from the Debian package file name (normally packages end with `_ARCH.deb`), but
can also be overriden via command-line arguments.

For more options and a more in-depth description of defaults run `beaver bintray
upload -h` for online help.

The most common way to upload files is to add this to your `.travis.yml`:

```yml
deploy:
    provider: script
    script: beaver bintray upload *.deb # Put the right locatio here
    skip_cleanup: true
    on:
        tags: true
```

And then define `$BINTRAY_USER` and `$BINTRAY_KEY` as secret/encrypted
repository environment variables.

Travis already have a provider for deploying to bintray, but it is extremely
inconvenient as it requires to produce one json file per file to upload.

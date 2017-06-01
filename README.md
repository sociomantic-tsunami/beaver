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

The docker image name is `beaver`.


beaver install
--------------

This command is an easy entry point for projects that want to use some
conventions.

This script just builds the image for now, but if the `$DIST` environment
variable is defined, then it looks for the `Dockerfile.$DIST` file instead of
the regular `Dockerfile`.

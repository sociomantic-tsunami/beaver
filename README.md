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
default options (`--pull -t $img` in particular).

The image name will be taken from the `BEAVER_DOCKER_IMG` environment variable,
if present. If not present it falls back to the result of `git config
hub.upstream` (in case you are using the
[git-hub](https://github.com/sociomantic-tsunami/git-hub) tool in the
command-line. If that's empty too, then it will try with the `TRAVIS_REPO_SLUG`
environment variable (in case it's running inside travis) and as a last resort
it will simply use `beaver` as the image name.

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
conventions. You can forward arguments to `docker build` by just passing the
arguments to `beaver install` (this is handy, for example, to pass `--arg` or
other options.

This command will look for a `beaver.Dockerfile` in your project and use it to
generate a `Dockerfile` if none is present. By using a `beaver.Dockerfile` you
can just use one docker image building specification for multiple base Ubuntu
distributions (this command assumes you are using
[Cachalot](https://github.com/sociomantic-tsunami/cachalot)-style images,
meaning the image tag should have the form `DIST-VERSION`).

Your `beaver.Dockerfile` only needs to define a `FROM` line in a special way,
only using as the tag, the image version **without** the distribution name.
So if you want to use `sociomantictsunami/dlang:{trusty,xenial}-v2`, you
should use:

```dockerfile
FROM sociomantictsunami/dlang:v2
```

Of course you can use other `Dockerfile` instructions here as needed.

The `beaver install` command will automatically *inject* the appropriate
distro name and some final instructions to copy everything in the `docker/`
directory to the image and run the `docker/build` script so you just need to
care to write a script to build the image (make sure it is executable). In the
script you can always use `$(lsb_release -cs)` to the what the current Ubuntu
version is and install different packages based on that, for example.

Here is a sample script:

```sh
set -xeu

apt-get update

if test "$(lsb_release -cs)" = trusty
then
    apt-get install -y python2
else
    apt-get install -y python3
fi
```

You can completely omit the `docker/build` script if you don't need any extra
build steps - if the script doesn't exist, nothing will be copied to the image
building procedure either.

The `Dockerfile` generation is performed by the `beaver docker gen-dockerfile`
command, please read the command help (`-h`) if you want to know the process
more in detail.

If generating the `Dockerfile` is not flexible enough for you, you can always
write a conventional, full, `Dockerfile` yourself. `beaver install` will search
for a `Dockerfile.$DIST` (or a plain `Dockerfile` if no `$DIST` is defined)
**before** looking for the `beaver.Dockerfile`.

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


Building D1/2 projects
----------------------

Beaver provides some facilities to build D1 projects that are compatible with D2
easily.

This assumes you are using:

- [MakD](https://github.com/sociomantic-tsunami/makd) (it might work for
  other build systems that use Make though).
- [Cachalot](https://github.com/sociomantic-tsunami/cachalot) `dlang` docker
  images.

There are 2 main possible setups:

1. Use the DMD provided by default by the image for some branch (dmd1,
   dmd-transitional or dmd). This method is only encouraged for unstable,
   bleeding-edge projects.

2. Specify a particular DMD version. Recommended especially for libraries that
   need to keep compatibility with multiple DMD versions, even among major
   branches.

Both approaches can be combined with Travis matrix builds, and in the following
examples, matrix will always be used because is the more general case, but to do
single builds just move the environment variables definition from `matrix:` to
`global:` and that's it.

Here is an example for case 1:

```yml
env:
    matrix:
        - DMD=dmd1
        - DMD=dmd-transitional

install: beaver dlang install

script: beaver dlang make
```

`beaver dlang install` accepts arbitrary arguments that will be forwarded
directly to the `beaver docker build` call.

`beaver dlang make` by default runs the targets `test`, but you can override it
by providing arguments. These arguments will be forwarded to `make` directly if
provided. This command will **always** first run `make d2conv` if there is a D2
compiler specified (and there is no file `.D2-ready` that contains the string
`ONLY`).

For example, to get verbose output for some PR for debugging reasons, you could
use `beaver dlang make V=1 test`.

To specify a version explicitly (case 2) you can use the same commands, but just
specify the version in the `$DMD` variable:

```yml
env:
    matrix:
        - DMD=1.079.0
        - DMD=1.080.0
        - DMD=2.070.2.s10
        - DMD=2.070.2.s12
        - DMD=2.074.0-0
```

In this case beaver will find out which is the package name to install and
install that specific version. The rest of the `.travis.yml` file stays the
same.

When using this command, you will need to use the `beaver.Dockerfile` feature
mentioned in the `beaver install` section. All mentioned there applies to this
command too, except that there is no fallback to `Dockerfile.$DIST`, since there
are many steps needed to setup the image automatically.

It will install the DMD version as requested via the `DMD` environment
variable (by injecting the `DMD_PKG` docker argument and environment variable to
the docker image generation, as well as calling `apt-get update && apt-get
install` with the requested DMD version for you.

This means you only have to take care of installing your project dependencies
and you don't need to do an `apt-get update` before the install.

Here is an example `beaver.Dockerfile` and `docker/build` script when using
`beaver dlang install`:

```dockerfile
FROM sociomantictsunami/dlang:v2
```

```sh
#!/bin/sh
apt-get install -f libwhatever-dev tool
```

Again, if you don't need extra dependencies, you can completely omit the
`docker/build` script.

The `beaver dlang make` command also uses some utilities that could come handy
if you want to write a custom build script. Take a look at the `lib/dlang.sh`
file, you'll find the utility functions with documentation in there.


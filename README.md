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


Passing option
--------------

Most options to the `beaver` commands and sub-commands are passed via
environment variables that start with `BEAVER_`. Options can also be passed via
CLI options by using `--option`, which at the end it also exports the equivalent
environment variable.

For example, `BEAVER_DOCKER_IMG=test beaver docker build` is the same as `beaver
--docker-img test docker install` (or `beaver --docker-img=test docker build`).

These options can only be passed at the beginning (before the beaver command),
so `beaver docker --docker-img test build` and `beaver docker build
--docker-img test` won't work).


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
if present (can also be passed via `beaver --docker-img=...` CLI option). If not
present it falls back to the result of `git config hub.upstream` (in case you
are using the [git-hub](https://github.com/sociomantic-tsunami/git-hub) tool in
the command-line. If that's empty too, then it will try with the
`TRAVIS_REPO_SLUG` environment variable (in case it's running inside travis) and
as a last resort it will simply use `beaver` as the image name.

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
`BEAVER_DOCKER_VARS` environment variable (or `beaver --docker-vars` CLI
option). To make it globally, you can do, for example:

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
`BEAVER_DOCKER_OPTS` (or using `beaver --docker-opts=--whatever docker ...`).

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

apt update

if test "$(lsb_release -cs)" = trusty
then
    apt install -y python2
else
    apt install -y python3
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


### Multiple Dockerfile contexts

Sometimes is useful to have multiple different docker contexts for a project.
The most typical case is having one (`beaver.`)`Dockerfile` for building
a project (with the build dependencies), and another one to run the project
(with the runtime dependencies). Since [Docker doesn't support specifying
a `.dockerignore` file yet](https://github.com/moby/moby/issues/12886), beaver
adds some support to overcome this limitation.

To use multiple build contexts, you can specify the variable
`BEAVER_DOCKER_CONTEXT` (or `--docker-context` CLI option) to point to
a directory that will contain your `Dockerfile` or `beaver.Dockerfile` and
possibly a `build` script (equivalent to the `docker/build` script in normal
builds) and/or a `dockerignore` (`.dockerignore is also accepted but
`dockerignore` will take precedence), which will be copied to the current
working directory as `.dockerignore`.

For example:
```
docker/builder/beaver.Dockerfile
docker/builder/build
docker/builder/dockerignore

docker/runner/Dockerfile.xenial
docker/runner/dockerignore
```

Where:

```console
$ cat docker/builder/dockerignore
*
!docker/builder/

$ cat docker/runner/dockerignore
*
!docker/runner/
```

(will ignore all files except for its context, all paths should be relative to
the current working directory, same for the `Dockerfile`s)


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
`prerelease` component (unless `-C <comp>` is used, in which case the component
will be force to be `<comp>` instead). Finally `ARCH` is the architecture and is
calculated from the Debian package file name (normally packages end with
`_ARCH.deb`), but can also be overriden via command-line arguments.

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


Codecov
-------

Beaver includes a convenient wrapper to send [codecov.io](https://codecov.io/)
reports. Just make sure the project was already built with coverage support and
then use something like this in the `.travis.yml` file:

```yml
after_success: beaver --codecov-reports="*.lst" codecov [OPTIONS]
```

The `[OPTIONS]` are forwarded directly to the
[codecov-bash](https://github.com/codecov/codecov-bash), but this script will
run in a confined docker instance where only the coverage reports are available,
plus the original source code as it was in Git (not the, possibly dirtly, build
workspace).

The docker images used to run the codecov script is determined by the standard
`BEAVER_DOCKER_IMG` variable, and it is expected that this image was build
before running `beaver codecov` (normally through the `beaver install` command
or similar).

Only `TRAVIS*` and `CODECOV_*` environment variables will be automantically
passed to the docker container. If you want to pass any other environment
variables use `BEAVER_DOCKER_VARS` as usual.

The reports location must be passed explicitly to the script via the
`BEAVER_CODECOV_REPORTS` environment variable (or `--codecov-reports` CLI
options). Glob patterns (like `*.lst`) and directories can be used (they will be
copied recursively), but special characters are not escaped from the shell, so
be careful if files have special characters, they must be properly escaped.

Some options are passed to codecov by default (at the moment `-n beaver -s
reports`, where `reports` is the location of the sanitized sandbox where reports
are copied; please check the `bin/beaver-codecov` script if you are interested
in the details).


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
single builds just convert the templates to a single job (or just define one
`test-matrix` job)  and that's it.

### Case 1

Here is an example for case 1:

```yml
env:
    global:
        - DIST=xenial
        - F=production

# Create docker images and setup environment to build
install: beaver dlang install

# Basic config is inherited from the global scope
jobs:
    templates:
        - &test-matrix
          stage: Test
          script: beaver dlang make

    include:
        - <<: *test-matrix
          env: DMD=dmd1
        - <<: *test-matrix
          env: DMD=dmd-transitional
```

Note that using [implicit matrix
expansion](https://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix)
is **strongly discouraged** as it gets quite tricky when using stages.

`beaver dlang install` accepts arbitrary arguments that will be forwarded
directly to the `beaver docker build` call.

`beaver dlang make` by default (when invoked with no arguments) will the
following:

1. `make d2conv` (if there is a D2 compiler specified and there is no file
    `.D2-ready` that contains the string `ONLY`).

2. `make` (without arguments to build the default target).

3. `make unittest` (and upload coverage reports to codecov, if any, using
   `beaver dlang codecov`, see *Codecov support* for more details).

4. `make integrationtest`.

When called with arguments, it will simply do one `make` call with those
arguments, without calling `make d2conv` automatically (but setting all
D-related environment variables appropriately).

For example, to get verbose output for some PR for debugging reasons, you could
use `beaver dlang make V=1 test`.

If you want to set some variable but still get the default `make` sequence, you
can simply export those variables via `BEAVER_DOCKER_VARS`.

### Case 2

To specify a version explicitly you can use the same commands, but just specify
the version in the `$DMD` variable:

```yml
env:
    global:
        - DIST=xenial
        - F=production

# Create docker images and setup environment to build
install: beaver dlang install

# Basic config is inherited from the global scope
jobs:
    templates:
        - &test-matrix
          stage: Test
          script: beaver dlang make

    include:
        - <<: *test-matrix
          env: DMD=1.079.0
        - <<: *test-matrix
          env: DMD=1.080.0
        - <<: *test-matrix
          env: DMD=2.070.2.s10
        - <<: *test-matrix
          env: DMD=2.070.2.s12
        - <<: *test-matrix
          env: DMD=2.074.0-0
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
the docker image generation, as well as calling `apt update && apt install` with
the requested DMD version for you.

Wildcards are supplied to `apt` as-is, which makes it possible to install latest
package which version string matches:

```yml
jobs:
    # templates...
    include:
        - <<: *test-matrix
          env: DMD=1.079.*
        - <<: *test-matrix
          env: DMD=2.070.2.s*
```


This means you only have to take care of installing your project dependencies
and you don't need to do an `apt update` before the install.

Here is an example `beaver.Dockerfile` and `docker/build` script when using
`beaver dlang install`:

```dockerfile
FROM sociomantictsunami/dlang:v2
```

```sh
#!/bin/sh
apt install -f libwhatever-dev tool
```

Again, if you don't need extra dependencies, you can completely omit the
`docker/build` script.

The `beaver dlang make` command also uses some utilities that could come handy
if you want to write a custom build script. Take a look at the `lib/dlang.sh`
file, you'll find the utility functions with documentation in there.


### Codecov support

Beaver includes a convenient wrapper to send [codecov.io](https://codecov.io/)
reports. Just make sure the project was already built with coverage support and
then use something like this in the `.travis.yml` file:

```yml
after_success: beaver dlang codecov [OPTIONS]
```

This command is based on the global `beaver codecov` command (please read the
documentation on this command for more details), but automatically selects which
reports to send, so you don't need to pass the `BEAVER_CODECOV_REPORTS`
environment variable. This will be automatically set to the `COVDIR` directory,
if defined, and it will default to MakD's default `COVDIR` otherwise (but it can
still be overridden via the `BEAVER_CODECOV_REPORTS` variable if needed).

Also some extra variables specific to D programs are passed and used as flags
(`DIST DMD DC F V` etc.). If you want to pass any other environment variables
use `BEAVER_DOCKER_VARS` as usual.

Please check the `bin/dlang/codecov` script if you are interested in the
details.


### Auto-convert and release tags for D2

For D1 projects that are compatible with D2, there is a special command that
allows automatically converting to D2, tagging (using the suffix `+d2`), pushing
to the repo and creating a GitHub release.

You'll need a GitHub OAuth token to be able to push and create the release, you
should provide it via the `$GITHUB_OAUTH_TOKEN` environment variable. This
command also expects the variables `$DIST`, `$TRAVIS_REPO_SLUG` and
`$TRAVIS_TAG` to be defined.

The recommended way to trigger it in the `.travis.yml` is via a special stage,
after all the rest of the tests passed, and it should be done only for tags.

For example:

```yml
# Don't run the job on auto-converted tags at all
if: NOT tag ~= \+d2$

env:
    global:
        # This should really be added via web or the travis tool, but ENCRYPTED
        - GITHUB_OAUTH_TOKEN=XXX
        - DIST=xenial
jobs:
    include:
        - stage: Test
          script: beaver dlang make
        - stage: D2 Release
          # Run only for tags, but not for auto-converted ones
          if: tag IS present AND NOT tag ~= \+d2$
          script: beaver dlang d2-release
```

If you use a matrix build then you might need to fix you `env:` too in the `D2
Release` stage. Here is a slightly more complicated example using a matrix build
and a main job using an `after_success:`:

```yml
# We will use docker to set up out environment, so don't use any particular
# language in Travis itself
language: generic

# Enable docker
sudo: required
services:
    - docker

# Disable automatic submodule fetching (it's done recursively)
git:
    submodules: false

# Global environment variables
env:
    global:
        - DIST=xenial
        # Make sure beaver is in the PATH
        - PATH="$(git config -f .gitmodules submodule.beaver.path)/bin:$PATH"

# Do a shallow submodule fetch
before_install: git submodule update --init

# Create docker images and setup environment to build
install: beaver dlang install

# Send codecov reports
after_success: beaver dlang codecov

# Basic config is inherited from the global scope
jobs:
    templates:
        - &test-matrix
          stage: Test
          script: beaver dlang make
          # Don't build tags already converted to D2
          if: NOT tag =~ \+d2$

    include:
        - <<: *test-matrix
          env: DMD=1.081.1 F=production
        - <<: *test-matrix
          env: DMD=1.081.1 DIST=xenial F=devel
        - <<: *test-matrix
          env: DMD=2.071.2.s12 DIST=xenial F=production
        - <<: *test-matrix
          env: DMD=2.071.2.s12 DIST=xenial F=devel
        - stage: D2 Release
          # We need to include the exclusion of D2 tags because this "if"
          # replaces the global one
          if: tag IS present AND NOT tag =~ \+d2$
          # We override it, otherwise is inherited from the first matrix row,
          # we need DIST and DMD for `beaver dlang install`
          env: DMD=2.070.2.s12 F=production
          # before_install and install are inherited
          script: beaver dlang d2-release
          # Overridden to NOP, otherwise is inherited
          after_success: true
```

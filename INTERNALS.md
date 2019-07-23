Beaver internals documentation
==============================

Beaver is a collection of scripts and utilities to keep
[Travis](https://travis-ci.org/) builds in a DRY fashion.

General structure
-----------------

The source code is mainly divided in:

- [`bin`](bin/)aries: intended to be used directly by the users
- [`lib`](lib/)raries: intended mostly to be used internally to implement the
  *binaries*
- [`tools`](tools/): utilities for users to better interact with beaver during
  development
- [`test`](test/)s: scripts to test beaver itself, trying to eat our own dog
  food

For details on particular files, just go to the source, Luke! In general
individual files are kept well documented, so instead of repeating the
documentation here, usually a link to the source file is included.

`bin`
-----

The main component of this is the [`beaver`](bin/beaver) binary. This script
will only forward arguments to sub-commands, which are implemented as
independent binaries, making sure the binaries directory is in the path,
providing help and listing facilities for sub-commands, etc.

Sub-commands can have two levels, which are handled by `beaver` and
auto-discovered based on the directory structure. Let's say the user runs
`beaver arg1 arg2 arg3`, then if an executable named `beaver-arg1` along where
`beaver` lives, it will run `beaver-arg1 arg2 arg3`. If it doesn't, but there
is a directory called `arg1` and inside it an executable called `arg1/arg2`,
then it will run `beaver/arg1/arg2 arg3`. If none is found, it will just exit
with an error.

In this context, `arg1` is said to be a *module* grouping a bunch of related
*sub-commands*. This scheme also allows developers to extend `beaver` by just
adding new subdirectories (modules) where the `beaver` command lives.

The `bin` directory can also contain independent utilities to be used outside of
beaver (or by beaver). For example, the [`codecov-bash`](bin/codecov-bash) is
shipped (for security reasons).

Every sub-command is implemented as an independent script, but a common pattern
is usually kept to make sure everything works even if `bin` is not included in
the `PATH`:

```sh
d="$(dirname "$0")"
# ...
$d/beaver ...
```

So far there are 3 modules: [`bintray`](bin/bintray/), [`dlang`](bin/dlang/)
and [`docker`](bin/docker/).


`lib`
-----

This directory contains shell scripts that are intended to be included (instead
of called) by the sub-commands via `. lib/LIB.sh`. It is common to have
libraries named the same as *modules* when sub-commands in a module share code,
but there are also general purpose libraries that are shared even among
different modules.

So far only 2 libraries are present:

* [`dlang.sh`](lib/dlang.sh): Utility functions for D build scripts.
* [`github.sh`](lib/github.sh): Utilities for interacting with GitHub.


`tools`
-------

For now this only holds [`make-wrapper-dlang`](tools/make-wrapper-dlang), a
script intended to be used as a wrapper for the `make` command. It will check if
beaver is present as a Git submodule in the current directory and if it is it
will call make insider docker using the dlang commands to build the project.


`test`
------

This directory holds the tests that are run to test `beaver` itself when `make
test` is ran. This calls [`local-test`](local-test) which is just a supporting
script to auto-discover and run tests in [`test/`](test/) adding `bin` to the
`PATH`, so `beaver` can be called directly from the tests.

[`test/single-test`](test/single-test) is an extra utility script used to run
the tests themselves and it will discover tests by looking for `*/test` or
`*/*/test` executable files (so `test` executables are search with at most 2
levels of sub-directories inside `test`. Those executables are run with it's own
path as the working directory, so each test directory provide an isolated test
description.

In general you can also find here sub-directories named the same as `beaver`
*modules*, but there are also other sub-directories testing common facilities or
use cases.

Each particular `test` executable normally just use standard `beaver` commands
to perform tasks and check if the desired results are achieved.

On the top-level, there are also `Dockerfile`s used for testing:
[`Dockerfile`](Dockerfile), [`Dockerfile.trusty`](Dockerfile.trusty) and
[`Dockerfile.xenial`](Dockerfile.xenial).

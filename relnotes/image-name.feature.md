* `docker build/run`

  The image name used to build images (and then used to run commands in
  containers based on those images now can be specified via the
  `BEAVER_DOCKER_IMG` environment variable.

  If not present it falls back to the result of `git config hub.upstream` (in
  case you are using the
  [git-hub](https://github.com/sociomantic-tsunami/git-hub) tool in the
  command-line.

  If that's empty too, then it will try with the `TRAVIS_REPO_SLUG` environment
  variable (in case it's running inside travis).

  If none of them are present, as a last resort, it will simply use `beaver` as
  the image name (which was the previously used, and hard-coded, name).

* `beaver install`

  This command learned to use the `beaver.Dockerfile` to generate the
  `Dockerfile`. The `Dockerfile.$DIST` still has precedence over the
  `beaver.Dockerfile` in case you really need to customize the `Dockerfile` in
  a way that `beaver docker gen-dockerfile` is not enough.

  By using a `beaver.Dockerfile` you can just use one docker image building
  specification for multiple base distributions. Your `beaver.Dockerfile` only
  needs to define a `FROM` line in a special way, only using as the tag, the
  image version **without** the distribution name.

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
  #!/bin/sh
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

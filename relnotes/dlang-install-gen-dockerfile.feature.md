* `beaver dlang install`

  This command, as `beaver install`, learned to use the `beaver.Dockerfile` to
  generate the `Dockerfile`. Please read the changes in `beaver install` to
  learn how to use this feature.

  This command works exactly like `beaver install` but it adds more sugar on
  top. It will install the DMD version as requested via the `DMD` environment
  variable (by injecting the `DMD_PKG` variable to the docker image generation,
  as well as calling `apt-get update && apt-get install` with the requested DMD
  version for you.

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

  **Note** that `beaver dlang install` won't fall back to use
  a `Dockerfile.$DIST`.

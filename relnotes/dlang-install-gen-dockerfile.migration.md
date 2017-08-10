* `beaver dlang install`

  This command use a much more automated approach to building the image, by
  using a `beaver.Dockerfile` and `docker/build` script (like `beaver install`).

  **Note** that, on the contrary to `beaver install` this command won't fall
  back to use a `Dockerfile.$DIST`, so you need to migrate to the new scheme.

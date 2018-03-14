### Multiple Dockerfile contexts for `beaver install`

Sometimes is useful to have multiple different docker contexts for a project.
The most typical case is having one (`beaver.`)`Dockerfile` for building
a project (with the build dependencies), and another one to run the project
(with the runtime dependencies). Since [Docker doesn't support specifying
a `.dockerignore` file yet](https://github.com/moby/moby/issues/12886), beaver
adds some support to overcome this limitation.

To use multiple build contexts, you can specify the variable
`BEAVER_DOCKER_CONTEXT` to point to a directory that will contain your
`Dockerfile` or `beaver.Dockerfile` and possibly a `build` script (equivalent
to the `docker/build` script in normal builds) and/or a `dockerignore`
(`.dockerignore is also accepted but `dockerignore` will take precedence), which
will be copied to the current working directory as `.dockerignore`.

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

### Temporary files are now removed

`beaver install` and `beaver dlang install`

Now these commands clean after themselves. The temporary files
`beaver.Dockerfile.generated` and `.dockerignore` will be automatically removed,
unless the command fail, in which case the they are kept for debugging purposes.

There is also a new `BEAVER_DEBUG` variable, when it's content is `1`, then the
temporary files will be kept even if the command succeed.

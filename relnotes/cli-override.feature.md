### Most options can be set also via CLI

`beaver`

The `beaver` command and sub-commands take some options that need to be
propagated to other sub-commands via environment variables. This could be too
verbose and bloated for some use cases.

Now any environment variable that starts with `BEAVER_` can be set via CLI. This
is done using a simple mapping, where `beaver --some-option value` is equivalent
to `BEAVER_SOME_OPTION=VALUE beaver`.

This kind of options can only be passed before a `beaver` command is specified
(so you can use `beaver command --some-option value`, you have to write it as
`beaver --some-option value command`.

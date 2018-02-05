## New general `codecov` command

A new, general, `beaver codecov` command was added, which is not tied to *dlang*
builds.

The new command is a wrapper for
[codecov-bash](https://github.com/codecov/codecov-bash) (the same as `beaver
dlang codecov` was), but assumes almost nothing about how to pass the reports.

Unlike `beaver dlang codecov`, the reports location must be passed explicitly to
the script via the `BEAVER_CODECOV_REPORTS` environment variable. Glob patterns
(like `*.lst`) and directories can be used (they will be copied recursively),
but special characters are not escaped from the shell, so be careful if files
have special characters, they must be properly escaped.

The `beaver dlang codecov` command is now based on the new `beaver codecov`
command.

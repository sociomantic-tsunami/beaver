bintray commands tests
======================

Tests for the `upload` subcommand should live in the `upload` directory, and
each file in that directory is a separate test and should have the following
format:
```
CMD
RET
OUT
...
```

Where:

- `CMD` is the full command to run (one line).
- `RET` is the expected return code for the command (one line).
- `OUT` is the expected output of the command. If `RET` is `0`, then this is
  expected to be the *stdout* output. Otherwise is expected to be the *stderr*
  output (multiple lines, all until the end of the file is considered the
  output).
